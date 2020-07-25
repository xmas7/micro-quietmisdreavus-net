---
layout: post
title: an API quandary
description: thinking out loud about a design problem in egg-mode
categories: code
---

I've been working on [egg-mode] a lot more in the past couple months. It's been nice to jump back
into it and get some long-standing issues resolved.

[egg-mode]: https://github.com/egg-mode-rs/egg-mode

Right now i'm working off-and-on to get the Direct Messages code up-to-date. Back in 2018, Twitter
changed how the API for DMs worked, which broke the existing code. However, egg-mode hasn't been
updated to the new API until now.

One of the changes was how they exposed getting a list of DMs for a user. Before, the endpoints to
pull a user's DMs were structured similarly to pulling a list of tweets: you would get a page of
results and could page back and forth based on the IDs of the messages you wanted to go
before/after. Now, pagination is more like getting a list of users: you get a page of results, as
well as an ID that you use to pull the next page.

The existing "get IDs for the next page" APIs are wrapped in egg-mode with the [`CursorIter`] type
and `Cursor` trait. This wraps the functionality to load a page of results, save the next/previous
page IDs, and query the next/previous page as desired. However, the new DM cursoring API works
differently from the `Cursor` trait: the page IDs are strings instead of numbers, and there is no
"previous page" ID to page backwards through results.

[`CursorIter`]: https://docs.rs/egg-mode/0.15.0/egg_mode/cursor/struct.CursorIter.html

In my current draft branch, i've decided to create a new `ActivityCursorIter` type that wraps the DM
cursoring APIs to provide a `Stream`-like API for them. However, there's one design wart in
`CursorIter` that i don't quite like: `CursorIter` is generic over the `Cursor` type, which isn't
actually the type the user cares about, in the end. If you're using `CursorIter` to load a list of
users, you want to eventually get a `Vec<TwitterUser>`, but you interact with a
`CursorIter<UserCursor>` (and call functions that return that type).

So now, my current draft `ActivityCursorIter` instead structures its support trait and types around
the *item* type, not the *cursor* type. There are still some raw types that most users won't care
about, but i feel like it's a bit better to see a function that returns
`ActivityCursorIter<DirectMessage>` instead of `ActivityCursorIter<DMCursor>` or the like. At least
that way, you know you're eventually getting some direct messages in the end, without having to
squint at the type name or click through a couple trait implementations.

One unfortunate side effect of this is that the DM cursor types are the same as the "raw" DM
deserialization types. As well, since i need to access those types from the trait implementation of
the public types, i need to expose those raw types publicly, even if it's masked by a
`#[doc(hidden)]` attribute to hide it from the public documentation.

(In all honestly, though, they would likely get exposed in the `raw` module that was introduced in
egg-mode 0.15.0. Since DMs aren't given directly in the response JSON like the other Twitter types
are, i want to expose a way for users of the `raw` API to load these types as well. The bad part
about doing it like this is that it requires me to create lots of sub-modules to break apart the
"public" types from the "raw" ones. In the end, i'm just very thankful for `pub(crate)` for letting
me expose things internally and then relocate them later for public consumption.)

-----

So this leaves the "quandary" from the post title. The thing i'm currently procrastinating working
on is deciding the question: Should i implement `ActivityCursorIter` like `CursorIter` (and have the
"raw" types in the public API) or should i write it like i mentioned above? If i do the latter,
should i also refactor `CursorIter` to work the same way? It all just seems like tedious busy-work,
and a potentially unnecessary API breakage. On the other hand, I like the idea of cleaning up the
main API to make it potentially easier to understand. I'm just not sure it would be worth the
effort.
