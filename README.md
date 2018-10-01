
# pupperbox

A Puppet Plan module that I use to setup my dev boxes.
This module is just for fun and comes with no guarantee that it will work for your environment. Use at your own risk, etc.


#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with pupperbox](#setup)
    * [What pupperbox affects](#what-pupperbox-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with pupperbox](#beginning-with-pupperbox)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Description

* Configures my user account, adds my SSH key to authorized_users, installs and configures my dev environment
* Installs some applications that I use

## Setup

### Setup Requirements

* [Bolt](https://puppet.com/docs/bolt/0.x/bolt_installing.html)
* A Linux box that you have SSH access to
* [Bolt configuration (and other info)](https://github.com/highb/jubilant-winner)

### Beginning with pupperbox

```
bolt plan run pupperbox::deploy -n somebox.example.com
bolt plan run pupperbox::deploy -n somebox.example.com username=elma
```

If you would like your public key to be synced, add or symlink it in `files/id_rsa.pub`

## Usage

Mostly see above.


## Limitations

* Tested on a CentOS 7 box.

## Development

If you manage to use this for your own purposes, awesome. If you find something is broken or could be improved, feel free to open a PR.
