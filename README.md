# Docker Field Manual - Code Examples Repository

**Companion repository for the Docker Field Manual book**

This repository contains all code examples, Dockerfiles, configuration files, and scripts referenced in the Docker Field Manual. All examples are organized by chapter for easy reference.

---

## 📖 About This Repository

This is the official code companion to **Docker Field Manual: A Comprehensive Guide to Containerization for Modern Software Development**.

- **200+ working code examples**
- **Production-ready templates**
- **Copy-paste friendly**
- **Tested and verified**
- **Organized by chapter**

---

## 📂 Repository Structure

```
docker-field-manual-code/
├── chapter-01-introduction/
│   ├── hello-world/
│   └── basic-commands/
├── chapter-02-architecture/
│   └── examples/
├── chapter-03-setup/
│   ├── linux/
│   ├── macos/
│   └── windows/
├── chapter-04-working-with-docker/
│   ├── images/
│   ├── containers/
│   ├── volumes/
│   └── networks/
├── chapter-05-docker-compose/
│   ├── basic-compose/
│   ├── multi-container/
│   ├── wordpress/
│   ├── nodejs-mongo/
│   └── production-ready/
├── chapter-06-advanced/
│   ├── multi-stage-builds/
│   ├── networking/
│   ├── security/
│   └── optimization/
├── chapter-07-practice/
│   ├── ci-cd/
│   │   ├── github-actions/
│   │   ├── gitlab-ci/
│   │   └── jenkins/
│   └── best-practices/
├── chapter-08-production/
│   ├── monitoring/
│   │   ├── prometheus/
│   │   └── grafana/
│   ├── logging/
│   ├── ha-deployment/
│   └── incident-response/
├── templates/
│   ├── dockerfiles/
│   │   ├── go/
│   │   ├── nodejs/
│   │   ├── python/
│   │   └── java/
│   └── docker-compose/
├── scripts/
│   ├── backup/
│   ├── deployment/
│   └── monitoring/
└── resources/
    ├── cheat-sheets/
    └── quick-reference/
```

---

## 🚀 Quick Start

### Clone the Repository

```bash
git clone https://github.com/fiber-pilot/docker-field-manual-code.git
cd docker-field-manual-code
```

### Run an Example

```bash
# Navigate to any example directory
cd chapter-05-docker-compose/wordpress

# Run the example
docker-compose up -d

# View logs
docker-compose logs -f

# Stop
docker-compose down
```

---

## 🎯 Examples by Chapter

### Chapter 1: Introduction to Docker ✅

**01. Hello World** - Your first Docker container
```bash
cd chapter-01-introduction/01-hello-world
# Follow README.md
```

**02. Basic Commands** - Essential Docker CLI operations
```bash
cd chapter-01-introduction/02-basic-commands
chmod +x commands.sh
./commands.sh
```

### Chapter 2: Docker Architecture  
*Coming soon* - Container internals, namespaces, cgroups

### Chapter 3: Setting Up Docker
*Coming soon* - Installation and configuration

### Chapter 4: Working with Docker ✅

**02. Python Flask App** - Production-ready Python Dockerfile
```bash
cd chapter-04-working-with-docker/02-python-flask-app
docker build -t flask-app .
docker run -p 5000:5000 flask-app
```

**03. Multi-Stage Build** - Optimized Node.js/TypeScript build
```bash
cd chapter-04-working-with-docker/03-multi-stage-build
docker build -t multistage-app .
# See README for size comparison
```

**04. Custom Networks** - Container communication and isolation
```bash
cd chapter-04-working-with-docker/04-custom-networks
# Follow network examples in README
```

### Chapter 5: Docker Compose ✅

### Chapter 6: Advanced Docker Usage
*Coming soon* - Advanced networking, security hardening, performance tuning

### Chapter 7: Docker in Practice ✅

**01. GitHub Actions** - Complete CI/CD pipeline
```bash
cd chapter-07-cicd/01-github-actions
# Copy deploy.yml to .github/workflows/
# See README for full setup
```

Features:
- Automated builds and tests
- Security scanning with Trivy
- Multi-environment deployment
- Multi-platform builds
- Layer caching

### Chapter 8: Production Deployment
*Coming soon* - High availability, monitoring, scaling

---

## 🎯 Production-Ready Templates

### Dockerfile Templates

Language-specific, production-optimized Dockerfiles:

- **Go**: Multi-stage build with scratch base
- **Node.js**: Security-hardened with Alpine
- **Python**: Poetry-based with virtual environments
- **Java**: Maven multi-stage with JRE

**Directory:** `templates/dockerfiles/`

### Docker Compose Templates

- Development environment
- Production deployment
- Microservices architecture
- Full-stack applications

**Directory:** `templates/docker-compose/`

---

## 🛠️ Utility Scripts

### Backup Scripts
- Volume backup/restore
- Image export/import
- Configuration backup

### Deployment Scripts
- Blue-green deployment
- Rolling updates
- Health checks

### Monitoring Scripts
- Container health monitoring
- Resource usage tracking
- Alert scripts

**Directory:** `scripts/`

---

## 📖 Quick Reference Materials

### Cheat Sheets
- Docker commands quick reference
- Dockerfile instructions
- Docker Compose syntax
- Common troubleshooting steps

### Quick Reference Cards
- Port mapping examples
- Volume mount patterns
- Network configuration
- Environment variables

**Directory:** `resources/`

---

## 🔧 Prerequisites

To run the examples in this repository, you need:

- **Docker Engine** 20.10 or later
- **Docker Compose** v2.0 or later
- **Git** for cloning the repository
- Basic command-line knowledge

### Verify Installation

```bash
docker --version
docker-compose --version
```

---

## 📝 Usage Guidelines

### Running Examples

1. **Navigate** to the example directory
2. **Read** the README.md in that directory
3. **Run** the example following the instructions
4. **Experiment** and modify as needed
5. **Clean up** when done

### Cleaning Up

Most examples include cleanup instructions. General cleanup:

```bash
# Stop all containers
docker-compose down

# Remove volumes (if needed)
docker-compose down -v

# Remove images (if needed)
docker-compose down --rmi all
```

---

## 🌟 Features

✅ **Tested Examples** - All code is tested and verified  
✅ **Production-Ready** - Templates follow best practices  
✅ **Well-Documented** - Each example includes README  
✅ **Copy-Paste Friendly** - Use directly in your projects  
✅ **Regular Updates** - Maintained and updated regularly  
✅ **Cross-Platform** - Works on Linux, macOS, Windows  

---

## 📚 Book Information

**Title:** Docker Field Manual: A Comprehensive Guide to Containerization for Modern Software Development

**Topics Covered:**
- Docker fundamentals and architecture
- Container and image management
- Docker Compose for multi-container apps
- Advanced networking and storage
- Security best practices
- Production deployment
- Monitoring and observability
- CI/CD integration

**Available:** Amazon KDP (Paperback)

---

## 🤝 Contributing

Found an issue or want to improve an example?

1. Fork the repository
2. Create a feature branch (`git checkout -b improve-example`)
3. Commit your changes (`git commit -am 'Improve XYZ example'`)
4. Push to the branch (`git push origin improve-example`)
5. Create a Pull Request

---

## 📄 License

All code examples are provided under the MIT License. Feel free to use them in your projects.

```
MIT License

Copyright (c) 2025 Docker Field Manual

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 🔗 Links

- **Book on Amazon:** [DFM: Docker Field Manual](https://www.amazon.com/dp/B0FWZLX64P)
- **Author Website:** [PTFM](https://purpleteamfieldmanual.com)
- **Report Issues:** [GitHub Issues](https://github.com/fiber-pilot/docker-field-manual-code/issues)
- **Discussions:** [GitHub Discussions](https://github.com/fiber-pilot/docker-field-manual-code/discussions)

---

## 📮 Support

- **Book Questions:** Check the book's appendices and troubleshooting guide
- **Code Issues:** Open a GitHub issue
- **General Questions:** Start a GitHub discussion

---

## 🎓 Learning Path

Recommended order for beginners:

1. Start with `chapter-01-introduction/`
2. Work through `chapter-04-working-with-docker/`
3. Practice with `chapter-05-docker-compose/`
4. Explore `templates/` for real-world patterns
5. Study `chapter-08-production/` for deployment

---

## ⚡ Quick Examples

### Run a Quick Test

```bash
# Simple web server
cd chapter-04-working-with-docker/containers/nginx-example
docker-compose up -d
curl http://localhost:8080
docker-compose down
```

### Try a Multi-Container App

```bash
# WordPress with MySQL
cd chapter-05-docker-compose/wordpress
docker-compose up -d
# Visit http://localhost:8080
docker-compose down -v
```

### Test Production Monitoring

```bash
# Prometheus + Grafana
cd chapter-08-production/monitoring/prometheus
docker-compose up -d
# Prometheus: http://localhost:9090
# Grafana: http://localhost:3000
docker-compose down -v
```

---

## 🏆 Best Practices

All examples follow Docker best practices:

- ✅ Multi-stage builds for smaller images
- ✅ Non-root users for security
- ✅ Health checks for reliability
- ✅ Proper logging configuration
- ✅ Resource limits
- ✅ Secrets management
- ✅ Network isolation
- ✅ Volume management

---

## 📊 Repository Stats

- **Total Examples:** 200+
- **Dockerfile Templates:** 12+
- **Docker Compose Files:** 25+
- **Utility Scripts:** 15+
- **Languages Covered:** Go, Node.js, Python, Java, PHP
- **Last Updated:** October 2025

---

## 🎯 What's Included

### For Beginners
- Step-by-step examples
- Detailed comments
- Troubleshooting tips
- Learning progression

### For Advanced Users
- Production patterns
- Performance optimization
- Security hardening
- Monitoring setup

### For DevOps
- CI/CD pipelines
- Deployment automation
- Infrastructure as Code
- Monitoring & alerting

---

## 📱 Stay Updated

Watch this repository to get notified of:
- New examples
- Updated best practices
- Bug fixes
- Additional templates

---

**Happy Dockerizing! 🐳**

*This repository is maintained as a companion to the Docker Field Manual book. All examples are regularly tested and updated to reflect current best practices.*
