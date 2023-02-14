## Description

iOSSportSearch is an MVVM reference app I wrote in Swift that demonstrates the
use of SQLite to load and search a large sporting goods product catalog.

## Requirements

• Support iPhone and iPad

• Import a large .csv describing a catalog of sporting goods

• Store the catalog in an SQLite database.

• Optimize for memory consumption and performance.

• Provide stats while the file is being processed.

• Provide an interface that allows the user to search the database.

## CSV Record format

Typical entries might look like this:

99000025001001,Underarmour NK Golf Shirt,14.97,14.97,Black,SM
99000025001002,Nike Golf Shirt UND,14.97,14.97,050,MD

## Assumptions

• The title field may contain multiple brand names, sometimes expressed with shorthands
  (aliases), in addition to a product title.
  
• The app should instantiate multiple individual products for a single input
  line if multiple brands names appear in the title field.

• A color is defined by both its name (e.g. "BLUE") and numeric shade value, when specified,
  so BLUE.400, BLUE.401 and BLUE.402 are considered different colors.

## Brand identification and product title cleanup

The data contained in the second title field is "dirty" in the sense that it often contains
brand abbreviations and misspellings, as well as potentially multiple brands within the same
title field. To handle this, I introduced three additional meta data files that are used to
identify brand names and cleaning up mispellings, etc. All input files for this project are
hosted on tyler.org:

• http://tyler.org/iOSSportSearch/catalog.csv       // sporting goods catalog

• http://tyler.org/iOSSportSearch/aliases.csv       // word/phrase aliases (first pass)

• http://tyler.org/iOSSportSearch/brandhints.csv    // brand names, aliases and or phrases to exclude from brand name names

• http://tyler.org/iOSSportSearch/brandmarks.csv    // brand-specific trademarks (e.g. "UNDER ARMOUR ARMOURFLEECE, CLUTCHFIT, etc.")

## Algorithm

• Strip extraneous size and color information from the end of the title field.

• Apply word/phrase aliases to title field

• Identify brands using metadata in brandhints.csv

• Use brandmarks.csv to handle product name trademarks that imply a certain brand,

  even if the brand is is missing from title field (e.g. "SKAGGERFLEECE", "ARMOURVENT")

## Extra credit

• Brand filtering "/nike"

• List all brands "/"

• Serial number fragment search (e.g. "#99000026001001", "#261000")

• Once loaded successfully, the app immediataely allows the user to search the catalog

  when the app restarts while updating the existing catalog in the background.
  
• Handle brand trademarks (see above)

## Testing

• This app uses the snapshot-testing package for view controller tests instead of a traditional XCode UI test.
  
• Snapshot tests require the iPhone 13 simulator in portrait mode.

• There are snapshot tests for light and dark modes.

• To run all tests, type ⌘-u.

• TestCatalog.csv is a subset of the master input file used for tests.
