## Description

iOSSportSearch is a high-performance, iPhone/iPad MVVM app that utilizes
SQLite to import and search a large sporting goods catalog efficiently.

• Downloads/ingests a 1M line .CSV file defining the catalog

• Stores data in SQLite

• Provides stats while loading

• Provides efficient search interface

## CSV Record examples

99000025001001,Underarmour NK Golf Shirt,14.97,14.97,Black,SM
99000025001002,Nike Golf Shirt UND,14.97,14.97,050,MD

## Complications

• The title field may refer to multiple brands, which are sometimes expressed
  using shorthands. "Armour Fleece" is an example that correlates to a specific
  Under Armour product line. 
  
• Multiple items can be instantiated by single input lines when multiple brands names
  are present.

• Color is defined by both name (e.g. "BLUE") and numeric shade value, if specified.

## Brand identification and product title cleanup

Data contained in title field is "dirty" in the sense that it often contains brand
abbreviations and/or misspellings, as well as potentially multiple brand name references
which should result in multiple catalog items associated with different brands but
sharing a description. To handle this, I introduced four additional metadata files used
to identify brand names, identify aliases, clean up mispellings, etc.

Metadata files:

• http://tyler.org/iOSSportSearch/catalog.csv       // catalog input file

• http://tyler.org/iOSSportSearch/aliases.csv       // word or phrase alias metadata

• http://tyler.org/iOSSportSearch/brandhints.csv    // brand name alias metadata

• http://tyler.org/iOSSportSearch/brandmarks.csv    // brand-specific trademark metadata

• http://tyler.org/iOSSportSearch/titlehints.csv    // title field hints used to ignore trailing noise

## Algorithm

• Strip extraneous size / color information from the end of title field

• Apply word/phrase aliases to title

• Identify brands using brandhints and brandmarks

## Features / Interface

• Brand filtering (e.g. "/nike")

• List all brands (e.g. "/")

• Search by serial number (fragment) (e.g. "#99000026001001", "#261000")

• Once loaded and restarted, the app will immediately allow user to search
  catalog while updating the catalog in the background, with progress
  indication in a subview.
  
## Testing

• To run all tests, type ⌘-u.

• Requires snapshot-testing Swift package for view tests.
  
• Snapshot tests require the Phone 13 simulator oriented in portrait mode.

• Snapshot tests support light and dark modes.

• TestCatalog.csv is a selected subset of the master input file designed to catch edge cases.
