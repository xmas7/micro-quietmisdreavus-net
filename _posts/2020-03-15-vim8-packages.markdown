---
layout: post
title: migrating from vim-pathogen to native vim packages
description:
  talking about how i updated my vim configuration to use the native package system available in vim
  8.x
categories: code
---

I recently was messing around with [my Vim configuration][vimfiles] (as one does) and realized that
i had an opportunity to change how i loaded the plugins i use. I was previously using [pathogen],
but as i had upgraded all my Vim installations to version 8[^version], i could start to use the
[built-in package support][packages]. This post describes my journey toward this migration.

[vimfiles]: https://github.com/QuietMisdreavus/vimfiles
[pathogen]: https://github.com/tpope/vim-pathogen
[packages]: https://vimhelp.org/repeat.txt.html#packages

[^version]: I hesitated using the Vim 8 packages support for a while because one of the systems i
  was using my configuration with was stuck on Vim 7 in a situation where i couldn't upgrade it. Now
  that i'm not using that system any more, all of my Vim installs have the native package support
  available!

## about vim plugins

It's worth talking about the Vim 8 package layout because it differs slightly from how Vim plugins
are normally structured. A Vim plugin tends to be structured as a set of Vim scripts in folders much
like the `.vim`/`vimfiles`[^vimfiles] directory: `autoload/`, `ftplugin/`, `colors/`, `syntax/`, and
so on.  Initially, these were meant to be integrated into your own Vim configuration so that in the
end you would create one assembled unit of Vim code.

[^vimfiles]: On Windows, the Vim configuration directory is called `vimfiles`, which is why my
  config repo is called that instead of `.vim`. As i'm occasionally an unapologetic Windows user, i
  like to highlight this difference.

Over time, as people created more and more things with Vim, many different ways of keeping these Vim
extensions apart appeared[^managers]. The core idea of any of these is like this: Rather than
merging all these files/folders into your main Vim configuration, separate them into different
directories so they can be managed separately. You can also provide different ways of specifying
what plugins you use, how they get loaded, how they get installed and updated, and so on.

[^managers]: There are far more plugin managers than i expected! While writing this post, i tried to
  find a list and saw [this Stack Exchange post][manager-post]. The individual answers have
  different reasonings about what constitutes a "plugin manager" and what makes one better than
  another, but suffice it to say that there are many ways to deal with using other people's scripts
  in your Vim configuration!

[manager-post]: https://vi.stackexchange.com/questions/388/what-is-the-difference-between-the-vim-plugin-managers

Eventually, Vim 8 (and Neovim before it) included a way to include these collections of scripts in a
way that they could be managed separately and also automatically included in your configuration.
However, they structured it a little differently than just "a bunch of copies of `.vim`/`vimfiles`",
so when i looked into it i was a little confused.

## about vim 8 packages

Vim 8 packages take the idea of "a bunch of copies of `.vim`/`vimfiles`" and add in the idea of
bundling several of these together into a cohesive package. They added a new `pack/` folder that it
checks in `.vim`/`vimfiles`, and the things that go in this folder work differently than `bundle` or
`plugged` or the like:

```
.vim/
- pack/
  - some-package-name/
    - start/
    |  - some-plugin/
    - opt/
       - some-other-plugin/
```

When Vim sees items in the `pack/` folder, it looks inside for `start/` and `opt/` subfolders. Items
in the `start/` subfolder are treated just like Pathogen treats items in the `bundle/` folder: It
adds that directory to `'runtimepath'` when Vim is launched. This causes that plugin to be available
for further use.

The interesting part comes in for plugins in the `opt/` folder. Those aren't loaded right away, but
they are made available for the new [`:packadd`] command. This way, plugins can be lazily loaded
only when they're needed, for example by running that in an auto-command or with a wrapper command.

[`:packadd`]: https://vimhelp.org/repeat.txt.html#:packadd

## migrating from pathogen

Anyway, with this detail out of the way, how do you actually migrate over from Pathogen? The short
answer:

```console
$ mkdir -p pack/asdf
$ git mv bundle pack/asdf/start
```

You can call the package folder whatever you'd like: Your username, the word `plugins`, some dummy
text, whatever. You could even go one step farther and separate out plugins based on their
functionality, like color schemes or syntax definitions. [(This is what i wound up
doing.)][my-layout].

[my-layout]: https://github.com/QuietMisdreavus/vimfiles/tree/8b4ece85fc2d2b6032be7951b7fd3ab83122516e/pack

Since Vim 8 packages are relatively new on the scene compared to the existing solutions, i'm not
sure how popular it will be to actually distribute things in that specific format. But i like the
fact that that automatic `'runtimepath'` management is now built-in, and that it has the capability
to optionally load things after startup. Since i was already using Pathogen and manually-tracked
Git submodules for my plugins, this works nicely for my purposes.
