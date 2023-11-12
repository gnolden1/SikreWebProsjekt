# Use a base image, for example, a basic Node.js image
FROM node:14

# Set the working directory
WORKDIR /app

# Copy your application files to the container
COPY package.json /app/
COPY server.js /app/

# Install dependencies
RUN npm install

# Expose a port (e.g., 3000) to access your web server
EXPOSE 3000

# Start your application
CMD ["node", "server.js"]
