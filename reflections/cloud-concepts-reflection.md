# Reflection: Cloud Computing in My Daily Life

## Cloud Services I Use

Every day, I rely on several cloud-based services without always thinking of them as "cloud computing." Three that stand out are **Google Drive**, **Netflix**, and **GCash**.

## Identifying the Models

**Google Drive** is a **SaaS (Software as a Service)** application. I use it directly through a browser or app without installing or managing any underlying software or servers — Google handles all of that. In terms of deployment model, it is a **Public cloud** service, since it runs on shared infrastructure managed by Google and is available to anyone with a Google account.

**Netflix** also falls under **SaaS**, since I simply consume a finished, ready-to-use streaming application without managing anything underneath it. Its deployment model is **Public cloud**, since the service is offered to the general public over shared, internet-based infrastructure.

**GCash** combines **SaaS** (the mobile app I use to send money and pay bills) with a **Private cloud** element in its backend. Financial apps typically keep transaction data and core banking logic on private, tightly controlled infrastructure for security and regulatory compliance, even while the customer-facing app feels like an ordinary public service.

## Git & GitHub for Cloud Projects

Version control is critical when working with cloud infrastructure because cloud projects are rarely built by one person alone, and mistakes can affect live systems used by real people. Git tracks every change and attributes it to whoever made it, making it possible to undo a bad change instantly instead of scrambling to fix a broken deployment. GitHub adds collaboration on top of that: teams can work on separate branches, review each other's code through pull requests before merging, and keep a full history of how a project evolved. This prevents conflicting changes from silently overwriting each other, keeps accountability clear, and gives cloud teams the confidence to experiment and roll back safely — essential when managing infrastructure other people depend on.
