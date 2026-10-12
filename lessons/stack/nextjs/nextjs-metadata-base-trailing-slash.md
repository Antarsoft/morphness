---
id: nextjs-metadata-base-trailing-slash
title: Rendered URLs drop the root's trailing slash
kind: testing-rule
target: project/TESTING.md
in_template: true
tags: { stack: [nextjs], service: [], area: [seo, testing] }
evidence: { fired: 1, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Rendered URLs drop the root's trailing slash

## Rule

URLs resolved against `metadataBase` drop the root's trailing slash, so canonical and sitemap URLs are compared with `new URL(x).href`, not as strings.

## Why

`https://host` failed a string match against the sitemap's `https://host/`.

## How to check

Grep URL equality assertions for normalization.
