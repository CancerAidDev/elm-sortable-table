# Examples

1. [U.S. Presidents by Birth Place](https://canceraiddev.github.io/elm-sortable-table/presidents.html)
2. [Travel Planner for the Mission District in San Francisco](https://canceraiddev.github.io/elm-sortable-table/travel.html)
3. [Paginated Table of Elements](#build-instructions-for-paginated-example)

## Build Instructions

To see the examples _without_ CSS, run the following commands:

```bash
git clone https://github.com/canceraiddev/elm-sortable-table.git
cd elm-sortable-table
cd examples
elm-reactor
```

Then navigate to `Presidents.elm` or `Travel.elm` from [localhost:8000](http://localhost:8000/). When using `elm-reactor`, refreshing a page that ends with `.elm` will recompile the code in that file and show you the new result.

## Build Instructions with CSS

To see the examples _with_ CSS, run the following commands:

```bash
git clone https://github.com/canceraiddev/elm-sortable-table.git
cd elm-sortable-table
yarn install
yarn parcel examples/presidents.html
```

Then open [localhost:1234/index.html](http://localhost:1234/index.html) in your browser. If you want to see the second example with CSS, you can compile it like this:

```bash
yarn parcel examples/travel.html
```

## Build Instructions for Paginated Example

The paginated example requires a simple [backend](https://github.com/canceraiddev/elm-sortable-table/blob/main/examples/server/index.js) that queries the included elements.db sqlite database.

To see the paginated [example](https://github.com/canceraiddev/elm-sortable-table/blob/main/examples/Elements.elm), run the following commands:

```bash
git clone https://github.com/canceraiddev/elm-sortable-table.git
cd elm-sortable-table
yarn install
node examples/server/index.js
```

Then in a separate terminal run the following command:

```bash
yarn parcel examples/elements.html
```

Then open [localhost:1234/index.html](http://localhost:1234/index.html) in your browser.
