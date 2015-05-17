# Collections

To build a new repo for a Cenit Collection, you can run

```bash
cenit collection foo --user-name=Miguel --user-email=sanchojaf@gmail.com --github-username=sanchojaf
```

By default its possible read the file `./gitconfig` from your pc

## Bootstrap a new project

Before proceeding, take a minute to setup your git environment, specifically setup your name and email for git and your username and token for GitHub:

```bash
$ git config --global user.email johndoe@example.com
$ git config --global user.name 'John Doe'
$ git config --global github.user johndoe
$ git config --global github.token 55555555555555
```

Then you can only do.

```ruby
cenit collection my_collection
```
