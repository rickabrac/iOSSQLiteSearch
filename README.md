## Description

iOSSportSearch is an MVVM app I wrote in Swift that demonstrates
use of SQLite to load and search a large sporting goods catalog.

• Downloads/ingests 1M line .CSV representing a sporting goods catalog

• Stores data in high-performance SQLite database

• Provides stats while loading catalog

• Provides efficient search interface

• Supports both iPhone and iPad

## CSV Record format

Typical entries:

99000025001001,Underarmour NK Golf Shirt,14.97,14.97,Black,SM
99000025001002,Nike Golf Shirt UND,14.97,14.97,050,MD

## Notes

• Title field may indicate multiple brands, sometimes expressed using shorthands.
  "Armour Fleece" is an example that correlates to a specific Under Armour product
  line. 
  
• Multiple items can be instantiated for single input lines when multiple brands names
  are present.

• Color is defined by both name (e.g. "BLUE") and numeric shade value, when specified.

## Brand identification and product title cleanup

Data contained in title field is "dirty" in the sense that it often contains brand
abbreviations and/or misspellings, as well as potentially multiple brand name references
which should result in multiple catalog items associated with different brands but
sharing a description. To handle this, I introduced four additional metadata files used
to identify brand names, identify aliases, clean up mispellings, etc.

Metadata files:

• http://tyler.org/iOSSportSearch/catalog.csv       // the sporting goods catalog

• http://tyler.org/iOSSportSearch/aliases.csv       // word/phrase aliases

• http://tyler.org/iOSSportSearch/brandhints.csv    // brand names, aliases and/or excluded phrases

• http://tyler.org/iOSSportSearch/brandmarks.csv    // brand-specific trademarks

• http://tyler.org/iOSSportSearch/titlehints.csv    // hints used to ignore trailing noise in title field

## Algorithm

• Strip extraneous size and color information from the end of title field

• Apply word/phrase aliases to title

• Identify brands using brandhints

• Use brandmarks to handle product name trademarks belonging to particular brand

## Features

• Brand filtering (e.g. "/nike")

• Listing of all brands ("/")

• Searching by serial number fragment (e.g. "#99000026001001", "#261000")

• Once loaded successfully and restarted, app will immediately allow user to search
  catalog while updating catalog in the background.
  
## Testing

• To run all tests, type ⌘-u.

• Requires snapshot-testing Swift package for all view controller tests.
  
• Snapshot tests require the Phone 13 simulator in portrait mode.

• Tests support light and dark modes.

• TestCatalog.csv is a subset of the live source.
