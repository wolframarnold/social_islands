Social Islands
==============

Copyright 20012-2015 by Wolfram Arnold & Weidong Yang. Released under BSD licence.

Visualization of social groups of your Facebook network.

Go to localhost:3000 and start logging in.

Engagement Stats
================

To get the engagement stats computed for a specific user, you can use this rake task

    rake stats:engagements FACEBOOK_UID=595045215

where the `FACEBOOK_PROFILE_ID` is the MongoDB ID for the given user. Instead of `FACEBOOK_PROFILE_ID` you can also
specify `FACEBOOK_UID=xxx` which is the Facebook UID.

How many users?
===============

Each incoming API request will create a `FacebookProfile` record for the user and one for each of their friends. So
how can I find out how many "direct" users we have?  With the following query (on the Mongo console):

    db.facebook_profiles.distinct('last_fetched_by')        // all records
    db.facebook_profiles.find({fetched_directly: true})
    db.facebook_profiles.distinct('last_fetched_by').length // number of records

The field `last_fetched_by` records who caused the fetch to happen which, for a friend's record is the user who logged in.


Resque
======

We have the following queues:

viz
---

This queue is read by the Java app (Jesque... class) to read a render request from the front-end.

fb_fetcher
-----------

This queue is both pushed to and serviced by the Rails app. Upon login, if an FB profile
for the user doesn't exist in our database yet, it'll push a job on the queue to download
the FB profile data (friends, connections,...). This is done asynchronously on a queue
because it can take up to ~10 seconds. At the end of the fb_fetcher job, it'll enqueue
the viz job.

To start the rails queue, you need to run:

    VERBOSE=1 QUEUES=fb_fetcher rake resque:work

To monitor whether the queues are up, you can check the processes with `ps aux | grep resque` or use
the `resque-web` tool. The worker will not pick up code changes automatically, you need to restart it for
that to happen.

User ID override
================

In development mode only (for security reasons), you can append a query parameter to override
the user_id of the profile being rendered. Default is the currently logged in user.

    http://localhost:3000/facebook?facebook_profile_id=123456789abc
    http://localhost:3000/facebook/png?facebook_profile_id=123456789abc     # png file
    http://localhost:3000/facebook/gexf?facebook_profile_id=123456789abc    # gexf file


EventSource HQ (ESHQ)
=====================

This is a Heroku add-on service implementing "Server-Side Events", an HTML5 technology for pushing data from
the sever to the client. It's a lighter-weight technology than Websockets, but it doesn't support bi-directional
communication. To run the app locally with this in place, you need to set the ESHQ environment veriables,
`ESHQ_KEY`, `ESHQ_SECRET` and `ESHQ_URL` which can be found from `heroku config`.

3Scale
======

3Scale manages API access, subscriber sign-up and authentication. This is effective only in the production environment.
The app requires an environment variable, `THREE_SCALE_PROVIDER_KEY`, to be set for this on Heroku.


Debugging
=========

Trigger just the Java backend job
---------------------------------

Push a Resque job directly onto the queue. See file `app/jobs/facebook_fetcher` for details.


Mongo
-----

### Pulling the Production Database

I've added a custom rake task that will pull down a copy of the production database and insert
it into the development database. The development database is dropped in the process.
**This is destructive to the local database!**

    rake mongohq:pull

(This relies on the `heroku config` command to read the production Mongo credentials, and
it's using as target the development database configured in the local `mongo.yml`.)

### Accessing the live production database

I've added a tool `script/mongo_production` which will launch the MongoDB console
connected to the ***live production database!*** This is incredibly helpful and
incredibly dangerous. Use it wisely.

    script/mongo_production

To remove a specific user's profile, run within the mongo console:

    wolf = db.users.find({name:"Wolfram Arnold",provider:'facebook'}).next()
    db.facebook_profiles.remove({user_id:wolf._id})

**Be careful this is the live database!!!**

Note that making a copy of the production database is preferable to direct access!


Reque-web
---------

To watch the resque queues of the production redis database, you can use script `script/resque-web-production`
which launches the `redis-web` tool connected to the ***live production redis database.***

    script/reque-web-production

If this fails, it may already be running. To kill it, run `resque-web -k`

