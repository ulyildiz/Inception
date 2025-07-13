# NGINX Security Configuration

This NGINX container uses environment variables and Docker secrets for secure configuration management.

## Environment Variables (.env file)

The following environment variables can be configured in `/srcs/Containers/NGINX/.env`:

- `DOMAIN_NAME`: The domain name for the server (can be overridden by secret)
- `SSL_CERT_PATH`: Path to SSL certificate file
- `SSL_KEY_PATH`: Path to SSL private key file
- `WEB_ROOT`: Document root directory
- `SSL_PROTOCOLS`: SSL/TLS protocols to enable
- `SSL_CIPHERS`: SSL cipher suites
- `HSTS_MAX_AGE`: HTTP Strict Transport Security max age

## Docker Secrets

The following secrets are used for sensitive configuration:

### nginx_domain
File: `/secrets/nginx.txt`
Contains the domain name for the server.

### ssl_config
File: `/secrets/ssl_config.txt`
Contains SSL certificate details in the following format:
```
Country (e.g., TR)
State (e.g., Istanbul)
City (e.g., Istanbul)
Organization (e.g., 42Istanbul)
```

## Changing Configuration for Different Environments

### Development Environment
```bash
# Update domain name
echo "dev.myapp.local" > secrets/nginx.txt

# Update SSL config for development
cat > secrets/ssl_config.txt << EOF
US
California
San Francisco
MyApp Dev
EOF
```

### Production Environment
```bash
# Update domain name
echo "myapp.com" > secrets/nginx.txt

# Update SSL config for production
cat > secrets/ssl_config.txt << EOF
US
California
San Francisco
MyApp Inc
EOF
```

### Staging Environment
```bash
# Update domain name
echo "staging.myapp.com" > secrets/nginx.txt

# Update SSL config for staging
cat > secrets/ssl_config.txt << EOF
US
California
San Francisco
MyApp Staging
EOF
```

## Security Benefits

1. **Secrets Management**: Sensitive data like domain names and SSL configurations are stored in Docker secrets
2. **Environment Separation**: Different environments can use different configurations without code changes
3. **No Hardcoded Values**: All sensitive values are externalized from the codebase
4. **Runtime Configuration**: SSL certificates and configurations are generated at runtime using secure values
5. **Flexible SSL Settings**: SSL protocols and ciphers can be configured via environment variables

## File Structure

```
srcs/Containers/NGINX/
├── .env                    # Environment variables
├── conf/
│   ├── nginx.conf         # Main NGINX configuration
│   └── default.conf.template # Virtual host template with variables
├── tools/
│   └── nginx_setup.sh     # Setup script that processes secrets and env vars
└── Dockerfile             # Container build instructions

secrets/
├── nginx.txt              # Domain name secret
└── ssl_config.txt         # SSL configuration secret
```
