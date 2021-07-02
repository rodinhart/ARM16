## Comments (2021/07/02)

The fields in a GID are ordered and the labels are transfered out of bounds (i.e. not part of the GID).
Data that relies on ordering is harder to extent and deals poorly with optional fields.
If I want to add a field, where does it go, and how will that relate to extentions others might have done.
Because there are no labels, GIDs are not self-describing and therefore harder to debug (e.g. is this a view-id or a property-id?).

> Although the latter JSON contains one less abstraction, prevalence and simplicity of IETF RFC2396 makes the former example an acceptable choice for the documents.

The URI has its origins in a largely text-based environment (unix, telnet, ftp etc) where direct user manipulation was common and finding the lowest common denominator (plain text) was important.
Just like we hardly ever directly type in phone numbers anymore when dialing someone, pack data are for machine consumption and structured data makes more sense.

> If we use GIDs for referencing entities, we only need to allocate memory for the entities that are currently exposed to the UI. 

We don't though. The changes list contains _all_ changes using GID, and has redundancy at several levels.

> `70 chars/GID * 2 bytes/char(UTF16) * 1M changed cells = 140MB`

That is a lot of memory for derived data of which only a fraction is on the screen at any one time.
140MB is half the memory used by the essential data of a big dataset, memory better spend to improve the value of the product.
My measurements show that choosing a more compact data format would reduce the size about 20x.
We know from end users that encounter the "oh snap" in the browser that garbage collecion is a real challenge.
Garbage collection doesn't seem to be linear, i.e. double the memory takes a lot more than double the CPU time.

> At a scale when we can make 1M changes, we will probably suffer from bigger memory and CPU problems than GIDs.

That is not a good argument, "something else is even worse", especially if changing it means migrating packs and impacting other teams.
We know from bitter experience that migration of any kind is very painful.

> If we don’t use GIDs, we would still need to create some ad-hoc synthetic ids to display the list of changes. These synthetic ids can be shorter (because of no gid:cell/PEOPLE prefix), but local ad-hoc conversions can easily eliminate this benefit depending on how they are implemented. We would have to think about the performance at a feature level rather than having a predictable and easy-to-use app-wide solution.

Yes, we would, and that is to be expected for a maturing product that faces more and more competition.
The product is not about developers, it is about customers.
Customers _pay_ to use orgvue, we _get paid_ to write orgvue.
The representation of big data is moving towards simple numeric arrays, indices and bitmasks.
This greatly decreases memory footprint, and greatly increases processing speed. A good example is Apache Arrow.


> We will need to agree on the object shapes and continuously monitor if our rules are still followed. 

This is not that different from GIDs: you need to agree on a spec, and have a library that generates to that spec.
A malformed GID could be produced if code doesn't use the library or respects the spec.

### summary
