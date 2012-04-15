# AsciiDag

AsciiDag is a script that converts ASCII art of directed acyclic graphs (DAGs), typically representing the history of a Git repository, into pretty pictures.

I.e., it turns this:

```
       A---B---C topic
      /
 D---E---F---G master
```

…into this:

![](http://cl.ly/3Z2S3z1c2T2e1N3j0R14/sample.png)

## Requirements

* [Graphviz](http://www.graphviz.org) (tested with v2.28.0)

## Usage

Given a `graph.txt` file that contains an ASCII DAG:

```
$ asciidag graph.txt graph.png
```

## Source

AsciiDag's Git repo is available on GitHub, and can be browsed at:

```
http://github.com/aroben/asciidag
```

and cloned with:

```
git clone git://github.com/aroben/asciidag.git
```

[![Build Status](https://secure.travis-ci.org/aroben/asciidag.png)](http://travis-ci.org/aroben/asciidag)

### Contributing

If you'd like to hack on AsciiDag, follow these instructions:

1. Fork the project to your own account
2. Clone down your fork
3. Create a thoughtfully named topic branch to contain your change
4. Hack away
5. Add tests and make sure everything still passes by running rake
6. If you are adding new functionality, document it in README.md
7. Do not change the version number, I will do that on my end
8. If necessary, rebase your commits into logical chunks, without errors
9. Push the branch up to GitHub
10. Send a pull request for your branch

## Copyright

Copyright © 2012 Adam Roben. See the LICENSE file for details.
