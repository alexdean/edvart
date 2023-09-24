## Overview

Scan ISBN codes with your fancy barcode scanner. Those which can be located
on [the Library of Congress SRU server](http://www.loc.gov/standards/sru/misc/simple.html)
will be saved as local [MARC](http://www.loc.gov/marc/faq.html#definition) records.

## Setup

```
$ bundle
$ bin/fetch
```

## TODO

 - separate 'barcode value' from ISBN.
 - Sort numeric parts of LCC numbers numerically.
 - "Read" status. (Date maybe?) Track what's been read & what hasn't.
 - Location. Will shelve books in different rooms. Will want to know where they are.
 - Extra categories I want to add. ("Celtic", "Native American", etc.)

## What Next?

I plan to use [Project Blacklight](http://projectblacklight.org/) to index the
MARC records I've retrieved this way.

## What's with the name?

I have a love/hate relationship with library tech. As often as not, my reaction
is best captured by [Edvart Munch's most famous painting](https://en.wikipedia.org/wiki/Edvard_Munch#The_Scream).
