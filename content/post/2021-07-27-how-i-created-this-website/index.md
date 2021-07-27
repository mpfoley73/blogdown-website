---
title: How I Created this Website
author: Michael Foley
date: '2021-07-27'
slug: how-i-created-this-website
categories:
  - Website
tags:
  - netify
  - blogdown
---

I have been listening to Emily Robinson and Jacqueline Nolis's <u>Build a Career in Data Science</u> on [Audible](https://www.audible.com/pd/Build-a-Career-in-Data-Science-Audiobook/B08NXJ6S38?action_code=ASSGB149080119000H&share_location=pdp). Chapter 4 explains how to go about creating a portfolio of data science projects. Your portfolio should demonstrate your skills, both in data analytics, and in communication. Emily and Jacqueline suggest you manage your code in GitHub repositories, and summarize your results in blog posts and Twitter posts. I have a [GitHub account](https://github.com/mpfoley73) with a few repos in it. So now I need a website to blog about what I've done. Following their suggestion, I investigated R blogdown. Here I am on day three posting my first entry, so I cannot be more pleased. Here is how I got here.

## Why Blogdown?

I read Yihui Xie's [blogdown: Creating Websites with R Markdown](https://bookdown.org/yihui/blogdown/) and followed along to create a site using the R **blogdown** package and publish it to the Netify web hosting service. The book is well written, but I managed to struggle anyway. This post relates some of the highlights and lowlights of my experience, and what you can do have more highs than lows.

**blogdown** is based on Hugo. It creates *static* web pages. That may sound limiting, but we're setting up a portfolio and blog here, not running e-commerce. The reason to **blogdown** instead of just Hugo is **blogdown** renders R markdown documents into html. With **blogdown**, you can write R markdown, knit the file, and show the results.

## Why Netify?

Yihui shows you how to work with several web hosting services, but recommends Netify ([https://www.netlify.com](https://www.netlify.com)). That's good enough for me. It has free options, and you can integrate it with GitHub to automatically update your web site when you commit changes to your main branch.

## The Gameplan

Here's what we want to do. 

1. Create a new repo on GitHub for our website files.
2. Create a website with **blogdown** in RStudio.
3. Create a website hosting account on Netify.
4. Personalize your website.
5. Start posting!

Let's go!

## 1. Create Your Repo

If you haven't done so already, create an account at github.com and install the desktop application on you pc. From the GitHub Desktop application, create a new repository. Mine is called "blogdown-website".

![GitHub Desktop dialog box for Creating a new respository](./create-repo-dialog.png "How I created my web site GitHub repo.")

I originally built my website first following the instructions in step 2. When I tried to host the website with Netify (step 3), I realized my website files belong in a repo. It shouldn't have been a big deal, but it took me a couple hours to undo the mess I made trying to move my website into the repo. My advice: *create your repo first.*

## 2. Create Your Website

Open you RStudio IDE. Install the **blogdown** package.

```
install.packages("blogdown")
```

Create a **Website using blogdown** project in your new repo.
