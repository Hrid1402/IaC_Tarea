const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");
const s3 = new S3Client();
const busboy = require("busboy");

const ALLOWED_MIME_TYPES = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10 MB

exports.handler = async (event) => {
    try {
        const contentType = event.headers?.['content-type'] || event.headers?.['Content-Type'] || '';

        const { v4: uuidv4 } = await import('uuid');

        if (contentType.includes('multipart/form-data')) {
            const fileData = await parseMultipart(event);
            
            if (!ALLOWED_MIME_TYPES.includes(fileData.mimeType)) {
                return { statusCode: 400, body: JSON.stringify({ error: "Formato no permitido. Solo se aceptan jpg, png, gif y webp." }) };
            }
            if (fileData.buffer.length > MAX_FILE_SIZE) {
                return { statusCode: 400, body: JSON.stringify({ error: "El archivo supera el límite de 10 MB." }) };
            }

            const extension = fileData.filename.split('.').pop();
            const fileKey = `${process.env.UPLOAD_PREFIX}${uuidv4()}.${extension}`;

            await s3.send(new PutObjectCommand({
                Bucket: process.env.S3_BUCKET,
                Key: fileKey,
                Body: fileData.buffer,
                ContentType: fileData.mimeType
            }));

            return {
                statusCode: 200,
                body: JSON.stringify({ message: "Imagen subida exitosamente", key: fileKey })
            };
        } 
        
        else {
            const body = event.isBase64Encoded ? Buffer.from(event.body, 'base64') : Buffer.from(event.body, 'utf-8');
            let jsonPayload;
            try {
                jsonPayload = JSON.parse(body.toString());
            } catch (e) {
                return { statusCode: 400, body: JSON.stringify({ error: "Cuerpo de petición inválido o formato no soportado." }) };
            }

            const { fileBase64, mimeType, filename } = jsonPayload;
            if (!fileBase64 || !mimeType) {
                return { statusCode: 400, body: JSON.stringify({ error: "Faltan los campos 'fileBase64' o 'mimeType'." }) };
            }

            if (!ALLOWED_MIME_TYPES.includes(mimeType)) {
                return { statusCode: 400, body: JSON.stringify({ error: "Formato no permitido. Solo se aceptan jpg, png, gif y webp." }) };
            }

            const fileBuffer = Buffer.from(fileBase64, 'base64');
            if (fileBuffer.length > MAX_FILE_SIZE) {
                return { statusCode: 400, body: JSON.stringify({ error: "El archivo supera el límite de 10 MB." }) };
            }

            const extension = filename ? filename.split('.').pop() : 'png';
            const fileKey = `${process.env.UPLOAD_PREFIX}${uuidv4()}.${extension}`;

            await s3.send(new PutObjectCommand({
                Bucket: process.env.S3_BUCKET,
                Key: fileKey,
                Body: fileBuffer,
                ContentType: mimeType
            }));

            return {
                statusCode: 200,
                body: JSON.stringify({ message: "Imagen subida exitosamente vía Base64", key: fileKey })
            };
        }

    } catch (error) {
        console.error("Error en la subida:", error);
        return { statusCode: 500, body: JSON.stringify({ error: error.message }) };
    }
};

function parseMultipart(event) {
    return new Promise((resolve, reject) => {
        const bb = busboy({ headers: { 'content-type': event.headers['content-type'] || event.headers['Content-Type'] } });
        let fileBuffer = [];
        let filename = '';
        let mimeType = '';

        bb.on('file', (name, file, info) => {
            filename = info.filename;
            mimeType = info.mimeType;
            file.on('data', (data) => fileBuffer.push(data));
            file.on('error', (err) => reject(err));
        });

        bb.on('finish', () => {
            resolve({
                buffer: Buffer.concat(fileBuffer),
                filename,
                mimeType
            });
        });

        bb.on('error', (err) => reject(err));
        
        const bodyBuffer = event.isBase64Encoded ? Buffer.from(event.body, 'base64') : Buffer.from(event.body, 'utf-8');
        bb.write(bodyBuffer);
        bb.end();
    });
}