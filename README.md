# Salesforce Advanced Enterprise Framework

Over my career as a Salesforce consultant, I have come to realise the need for a consistent, multi-domain, execution framework that is scalable and modular. 

The need for consistency, maintainability and scalability (amongst other things) led me to build this framework which is a collection of my own enterprise principles in addition to thinking from other thought leaders in the industry! 

This framework utilises enterprise patterns including:
- Domains
- Selectors
- Unit of Work
- Services
- Async Framework (using Platform Event architecture)
- ApexMocks based unit testing (credit to FinancialForce.com, inc)

## Key Principles

- Performance
- Security
- Scalability
- Modular Approach to Development
- Highly Performant, High Quality Apex Tests
- Dynamic SOQL with Concrete Referencing

## Prerequisites

You will need ApexMocks library as this library is heavily utilised for testing

## Getting Started

Clone the repo: `git clone https://github.com/nathanfranklinau/sf-advanced-enterprise-framework.git`

Create a scratch org: `sfdx force:org:create -f config/project-scratch-def.json -a [your scratch org alias] -v [dev hub org]`

Clone & Push Apex Mocks: https://github.com/apex-enterprise-patterns/fflib-apex-mocks 
OR Deploy: [<img src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">](https://githubsfdeploy.herokuapp.com?owner=apex-enterprise-patterns&repo=fflib-apex-mocks)

Push Source: `sfdx force:source:push -u [scratch org alias]`

Optionally deploy a Platform Event subscriber config to change the running user for Async Processing by modifying `src-env-specific/PlatformEventSubscriberConfigs/aef_AsyncWorkerEventTriggerConfig.platformEventSubscriberConfig` and then deploy using `sfdx force:mdapi:deploy -d src-env-specific/` 

Optionally assign the special permission set to allow the Platform Event running user to change audit field values such as CreatedBy and CreatedDate using: `sfdx force:user:permset:assign -n aef_SetAuditFields -u [scratch org alias]`

Optionally grab the samples from https://github.com/nathanfranklinau/sf-advanced-enterprise-framework-samples

## Design Considerations

1. This framework contains advanced concepts which might be overkill for smaller environments. These are fundamentally solid principles, however, they aren't for every environment.
2. Async Framework architecture is driven using Platform Events. There are pro's and con's to this approach vs using Async Triggers (via CDC). It's important to understand what limits are consumed using each approach. Two limits in particular consumed in the Async Framework are daily Queueable limits and hourly Platform Event publishes.
3. The framework is designed for use in a multi-business-domain environment. Smaller environments may not need this complexity.
4. ApexMocks is used extensively (and so it should be!), however, there is a steep learning curve to use it effectively.
5. New features are still to come! The roadmap will be implemented as time allows.

## Samples

All samples are available in the https://github.com/nathanfranklinau/sf-advanced-enterprise-framework-samples. repo. There are samples for invoking the Async Framework, samples for building Domains, and, samples for building Selectors. The Domains also invoke the Async Framework too.

## Documentation (WIP)

https://aef.enterpriseminded.com/

## Roadmap

- Documentation
- Versioned Releases
- More Samples
- Optimisation to get changed fields state in trigger handlers to reduce looping
- Implementation of Before/After Delete in Triggers
- Test Classes for Sample Code
