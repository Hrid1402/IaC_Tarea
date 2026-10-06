const { S3Client, GetObjectCommand, PutObjectCommand } = require("@aws-sdk/client-s3");
const s3 = new S3Client();
const sharp = require("sharp");

exports.handler = async (event) => {
    console.log("Evento SQS recibido:", JSON.stringify(event, null, 2));
    const batchItemFailures = [];

    for (const record of event.Records) {
        try {
            const body = JSON.parse(record.body);
            
            const bucketName = process.env.S3_BUCKET;
            const rawKey = body.key || body.Records?.[0]?.s3?.object?.key;

            if (!rawKey) {
                console.error("No se encontró la llave del archivo en el mensaje:", record.messageId);
                continue;
            }

            // Decodificar la llave enviada por S3 (ej. espacios "+" o "%20")
            const fileKey = decodeURIComponent(rawKey.replace(/\+/g, " "));

            console.log(`Procesando imagen: ${fileKey} del bucket: ${bucketName}`);

            const getObjectResponse = await s3.send(new GetObjectCommand({
                Bucket: bucketName,
                Key: fileKey
            }));

            const imageBuffer = await streamToBuffer(getObjectResponse.Body);

            const circleMask = Buffer.from(
                `<svg width="40" height="40"><circle cx="20" cy="20" r="20" fill="white"/></svg>`
            );

            const processedBuffer = await sharp(imageBuffer)
                .resize(40, 40, { fit: 'cover' })
                .composite([{
                    input: circleMask,
                    blend: 'dest-in'
                }])
                .png()
                .toBuffer();

            const fileName = fileKey.split('/').pop();
            const outputKey = `${process.env.PROCESSED_PREFIX}crop-${fileName.replace(/\.[^/.]+$/, "")}.png`;

            await s3.send(new PutObjectCommand({
                Bucket: bucketName,
                Key: outputKey,
                Body: processedBuffer,
                ContentType: "image/png"
            }));

            console.log(`Imagen recortada guardada exitosamente en: ${outputKey}`);

        } catch (error) {
            console.error(`Error procesando el registro SQS ${record.messageId}:`, error);
            batchItemFailures.push({ itemIdentifier: record.messageId });
        }
    }

    return { batchItemFailures };
};

async function streamToBuffer(stream) {
    return new Promise((resolve, reject) => {
        const chunks = [];
        stream.on("data", (chunk) => chunks.push(chunk));
        stream.on("error", (err) => reject(err));
        stream.on("end", () => resolve(Buffer.concat(chunks)));
    });
}