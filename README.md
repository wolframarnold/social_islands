Social Islands

Visualization of social groups of your Facebook network.

Go to localhost:3000 and start logging in.

Engagement Stats
================

To get the engagement stats computed for a specific user, you can use this rake task

    rake engagements:photos USER_ID=...

where the `USER_ID` is the MongoDB ID for the given user. Instead of `USER_ID` you can also
specify `UID=xxx` which is the Facebook UID.

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

    QUEUES=fb_fetcher rake resque:work

User ID override
================

In development mode only (for security reasons), you can append a query parameter to override
the user_id of the profile being rendered. Default is the currently logged in user.

    http://localhost:3000/facebook?user_id=123456789abc

EventSource HQ (ESHQ)
=====================

This is a Heroku add-on service implementing "Server-Side Events", an HTML5 technology for pushing data from
the sever to the client. It's a lighter-weight technology than Websockets, but it doesn't support bi-directional
communication. To run the app locally with this in place, you need to set the ESHQ environment veriables,
`ESHQ_KEY`, `ESHQ_SECRET` and `ESHQ_URL` which can be found from `heroku config`.

Debugging
=========

Trigger just the Java backend job
---------------------------------

Push a Resque job directly onto the queue. See file `app/jobs/facebook_fetcher` for details.


Mongo
-----

I've added a tool `script/mongo_production` which will launch the MongoDB console
connected to the ***live production database!*** This is incredibly helpful and
incredibly dangerous. Use it wisely.

    script/mongo_production

To remove a specific user's profile, run within the mongo console:

    wolf = db.users.find({name:"Wolfram Arnold",provider:'facebook'}).next()
    db.facebook_profiles.remove({user_id:wolf._id})


**Be careful this is the live database!!!**

This command uses the heroku gem to dynamically discover the Mongo connection
parameters and then launched the Mongo console with these.

Reque-web
---------

To watch the resque queues of the production redis database, you can use script `script/resque-web-production`
which launches the `redis-web` tool connected to the ***live production redis database.***

    script/reque-web-production

If this fails, it may already be running. To kill it, run `resque-web -k`

