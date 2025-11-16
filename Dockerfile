FROM node:18-alpine

WORKDIR /app

# Copiar archivos de dependencias
COPY package*.json ./

# Instalar dependencias
RUN npm install --production

# Copiar el código de la aplicación
COPY index.js ./

# Exponer el puerto
EXPOSE 3000

# Variables de entorno por defecto
ENV PORT=3000
ENV APP_COLOR=blue

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

# Comando para ejecutar la aplicación
CMD ["npm", "start"]