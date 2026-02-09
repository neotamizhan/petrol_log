# CLAUDE.MD - Cost-Optimized Development Guidelines

## Purpose
This document provides guidelines for interacting with Claude AI to produce maintainable, cost-effective code suitable for financial institutions with strict budget and operational constraints.

## Core Principles

### 1. Cost Optimization Strategy
- **Minimize API Calls**: Request complete, working solutions in single interactions
- **Efficient Prompting**: Be specific and detailed upfront to avoid iterative refinements
- **Batch Operations**: Group related requests together
- **Cache-Friendly**: Request reusable components and patterns

### 2. Code Quality Requirements
- **Production-Ready**: Code should be deployment-ready with minimal modifications
- **Well-Documented**: Include inline comments and README files
- **Error Handling**: Comprehensive error handling and logging
- **Security First**: Follow security best practices for financial services

### 3. Infrastructure Cost Efficiency
- **Serverless-First**: Prefer serverless architectures (AWS Lambda, Cloud Functions)
- **Minimal Dependencies**: Reduce dependency bloat and maintenance overhead
- **Stateless Design**: Enable horizontal scaling and reduced infrastructure costs
- **Resource Optimization**: Efficient memory and CPU usage patterns

## Prompting Best Practices

### Effective Prompt Structure
```
Context: [What you're building and why]
Requirements:
- Functional requirements
- Non-functional requirements (performance, security)
- Constraints (budget, technology stack)
Expected Output:
- Complete working code
- Documentation
- Deployment instructions
```

### Example Prompt
```
Context: Building a transaction monitoring API for financial institution

Requirements:
- REST API with 3 endpoints (create, read, list)
- PostgreSQL database
- JWT authentication
- Rate limiting (100 req/min)
- Audit logging
- Deploy on AWS Lambda
- Budget: $50/month for 10k transactions

Expected Output:
- Complete Python/Node.js code
- Infrastructure as Code (Terraform/CloudFormation)
- Deployment guide
- Cost estimation
```

## Technology Stack Preferences

### Backend (Serverless)
- **AWS Lambda** with Python 3.11+ or Node.js 20+
- **API Gateway** for REST endpoints
- **DynamoDB** for simple use cases (free tier eligible)
- **RDS Proxy** for PostgreSQL (connection pooling)

### Frontend
- **Static Site Generation**: Next.js, Astro, Hugo
- **CDN**: CloudFront, Cloudflare Pages (free tier)
- **Minimal JS**: Reduce bundle sizes

### Database
- **Managed Services**: RDS, Aurora Serverless v2
- **NoSQL**: DynamoDB (pay-per-request)
- **Caching**: Redis/Elasticache only when justified

### Storage
- **S3**: Standard tier for active, Glacier for archives
- **Lifecycle Policies**: Automatic cost reduction

## Code Structure Requests

### Request Complete Projects
Ask for:
- `/src` - Source code
- `/tests` - Unit and integration tests
- `/docs` - Architecture and API documentation
- `/infrastructure` - IaC templates
- `README.md` - Setup and deployment guide
- `.env.example` - Configuration template
- `requirements.txt` or `package.json` - Dependencies

### Request Modular Design
- Separate concerns (routes, business logic, data access)
- Reusable utilities and helpers
- Configuration externalization
- Environment-based settings

## Cost Monitoring Requirements

### Include in All Projects
```python
# Example: Cost tracking decorator
import time
from functools import wraps

def track_execution(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        start = time.time()
        result = func(*args, **kwargs)
        duration = time.time() - start
        # Log duration for cost analysis
        print(f"{func.__name__}: {duration:.2f}s")
        return result
    return wrapper
```

### Request Cost Estimates
Always ask Claude to provide:
- Monthly cost projections
- Cost per transaction/request
- Scaling cost implications
- Alternative approaches with cost comparison

## Security & Compliance

### Required Security Features
- **Authentication**: JWT, OAuth 2.0
- **Authorization**: Role-based access control (RBAC)
- **Encryption**: At-rest and in-transit (TLS 1.3+)
- **Input Validation**: Prevent injection attacks
- **Secrets Management**: AWS Secrets Manager, HashiCorp Vault
- **Audit Logging**: Immutable logs for compliance

### Compliance Considerations
- **Data Residency**: Specify geographic requirements
- **PII Handling**: Encryption, anonymization
- **Retention Policies**: Automated data lifecycle
- **Access Controls**: Principle of least privilege

## Performance Optimization

### Request Optimized Code
- **Database**: Indexed queries, connection pooling
- **Caching**: Redis for frequently accessed data
- **Async Operations**: Non-blocking I/O
- **Batch Processing**: Reduce API calls
- **Compression**: Gzip responses

### Monitoring Requests
Ask for:
- CloudWatch/Datadog integration
- Custom metrics (latency, error rates)
- Alerting thresholds
- Cost anomaly detection

## Deployment Strategy

### CI/CD Pipeline
Request complete GitHub Actions/GitLab CI configurations:
- Automated testing
- Security scanning (SAST, dependency checks)
- Infrastructure deployment
- Blue-green or canary deployments

### Infrastructure as Code
Always use:
- **Terraform** (preferred for multi-cloud)
- **CloudFormation** (AWS-specific)
- **Pulumi** (for complex logic)

Version control all IaC templates.

## Maintenance & Operations

### Request Operations Documentation
- Runbooks for common issues
- Disaster recovery procedures
- Backup and restore processes
- Scaling guidelines
- Cost optimization checklist

### Monitoring & Observability
- Centralized logging (CloudWatch Logs, ELK)
- Distributed tracing (X-Ray, Jaeger)
- Performance metrics
- Business metrics (transactions, revenue)

## Example Request Templates

### 1. New Microservice
```
Create a cost-optimized user authentication microservice:
- AWS Lambda + API Gateway
- PostgreSQL RDS (t4g.micro)
- JWT tokens with 24h expiry
- Rate limiting: 1000 req/hour per IP
- Expected load: 50k users, 500k logins/month
- Budget: $30/month
- Include: complete code, tests, Terraform, deployment guide
```

### 2. Data Processing Pipeline
```
Build a batch processing pipeline:
- Process 100k CSV records daily
- AWS Lambda + S3 + SQS
- Transform and load to PostgreSQL
- Error handling and retry logic
- Budget: $20/month
- Include: code, IaC, monitoring, cost breakdown
```

### 3. Static Website
```
Create a documentation website:
- Astro or Hugo static site generator
- Deploy to CloudFront + S3
- CI/CD with GitHub Actions
- Custom domain support
- Budget: $5/month (mostly DNS)
- Include: complete site, deployment workflow
```

## Cost Review Checklist

Before deploying any solution:
- [ ] All resources use appropriate sizing (not over-provisioned)
- [ ] Auto-scaling configured with reasonable limits
- [ ] Unused resources automatically cleaned up
- [ ] Caching implemented where beneficial
- [ ] Database queries optimized with indexes
- [ ] Monitoring and alerting configured
- [ ] Cost anomaly detection enabled
- [ ] Monthly budget alerts set
- [ ] Resource tagging for cost allocation
- [ ] Free tier maximized where possible

## Anti-Patterns to Avoid

### Don't Request
- ❌ Monolithic applications (hard to scale cost-effectively)
- ❌ Always-on EC2 instances for low-traffic apps
- ❌ Synchronous processing for long-running tasks
- ❌ Direct database connections from Lambda (use connection pooling)
- ❌ Unoptimized Docker images (large sizes = higher costs)
- ❌ Missing resource cleanup (zombie resources)

### Do Request
- ✅ Event-driven architectures
- ✅ Serverless-first designs
- ✅ Managed services over self-managed
- ✅ Auto-scaling with appropriate limits
- ✅ Resource tagging and cost allocation
- ✅ Regular cost optimization reviews

## Continuous Improvement

### Monthly Reviews
- Analyze AWS Cost Explorer reports
- Identify optimization opportunities
- Review unused or underutilized resources
- Update this document with lessons learned

### Quarterly Audits
- Security compliance check
- Performance benchmarking
- Technology stack updates
- Disaster recovery testing

## Additional Resources

- AWS Well-Architected Framework: https://aws.amazon.com/architecture/well-architected/
- FinOps Foundation: https://www.finops.org/
- Cloud Cost Optimization: https://www.cloudcostoptimization.com/
- OWASP Top 10: https://owasp.org/www-project-top-ten/

## Version History
- v1.0 (2025-02-08): Initial version

---

**Remember**: Every dollar saved on infrastructure is a dollar available for business value. Always ask Claude to explain cost implications and provide alternatives.
