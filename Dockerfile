FROM node:18-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install --production

COPY index.js ./

EXPOSE 3000

ENV PORT=3000
ENV APP_COLOR=blue

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

CMD ["npm", "start"]