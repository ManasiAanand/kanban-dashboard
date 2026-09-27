# .............stage 1 Build .............
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

#.....................stage 2 Runtime ..............
FROM node:20-alpine
WORKDIR /app
RUN npm install -g serve
COPY --from=build /app/dist ./dist
RUN chown -R node:node /app
USER node
EXPOSE 5173
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
CMD wget --no-verbose --tries=1 --spider http://localhost:5173/ || exit 1
CMD ["serve" , "-s" , "dist" , "-l" , "5173"]


