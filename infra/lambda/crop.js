const { S3Client, GetObjectCommand, PutObjectCommand } = require("@aws-sdk/client-s3");
const s3 = new S3Client();
const sharp = require("sharp");

exports.handler = async (event) => {
    console.log("Evento SQS recibido:", JSON.stringify(event, null, 2));

    for (const record of event.Records) {
        try {
            // Parsear el mensaje que viene desde SQS (asumiendo que contiene la ruta o el evento de S3)
            const body = JSON.parse(record.body);
            
            // Si el mensaje viene directo de un evento de S3 o de tu upload-lambda,
            // extraemos el nombre del bucket y la llave (key) del archivo original.
            const bucketName = process.env.S3_BUCKET;
            const fileKey = body.key || body.Records?.[0]?.s3?.object?.key;

            if (!fileKey) {
                console.error("No se encontró la llave del archivo en el mensaje.");
                continue;
            }

            console.log(`Procesando imagen: ${fileKey} del bucket: ${bucketName}`);

            // 1. Descargar la imagen original desde S3
            const getObjectResponse = await s3.send(new GetObjectCommand({
                Bucket: bucketName,
                Key: fileKey
            }));

            // Convertir el stream de S3 a un Buffer de Node.js
            const imageBuffer = await streamToBuffer(getObjectResponse.Body);

            // 2. Crear una máscara SVG circular para recortar la imagen en formato 40x40 con fondo transparente
            const circleMask = Buffer.from(
                `<svg width="40" height="40"><circle cx="20" cy="20" r="20" fill="white"/></svg>`
            );

            // 3. Procesar con Sharp 0.33 (Redimensionar a 40x40 y aplicar máscara circular con alfa)
            const processedBuffer = await sharp(imageBuffer)
                .resize(40, 40, { fit: 'cover' })
                .composite([{
                    input: circleMask,
                    blend: 'dest-in' // Aplica transparencia fuera de la máscara circular
                }])
                .png() // Exportar como PNG con canal alfa transparente
                .toBuffer();

            // 4. Definir la nueva ruta en el prefijo 'processed/'
            const fileName = fileKey.split('/').pop();
            const outputKey = `${process.env.PROCESSED_PREFIX}crop-${fileName.replace(/\.[^/.]+$/, "")}.png`;

            // 5. Guardar la imagen procesada de vuelta en S3
            await s3.send(new PutObjectCommand({
                Bucket: bucketName,
                Key: outputKey,
                Body: processedBuffer,
                ContentType: "image/png"
            }));

            console.log(`Imagen recortada guardada exitosamente en: ${outputKey}`);

        } catch (error) {
            console.error("Error procesando el registro individual:", error);
            // Lanzar el error o dejar que falle para que SQS reintente o lo mande a la DLQ según configuración
            throw error;
        }
    }

    return { statusCode: 200, body: JSON.stringify({ message: "Procesamiento de recorte completado con éxito." }) };
};

// Función auxiliar para convertir un Stream de AWS SDK v3 a Buffer
async function streamToBuffer(stream) {
    return new Promise((resolve, reject) => {
        const chunks = [];
        stream.on("data", (chunk) => chunks.push(chunk));
        stream.on("error", (err) => reject(err));
        stream.on("end", () => resolve(Buffer.concat(chunks)));
    });
}