# CompareXML

[![Gem Version](https://badge.fury.io/rb/compare-xml.svg)](https://rubygems.org/gems/compare-xml)

CompareXML is a fast, lightweight and feature-rich tool that will solve your XML/HTML comparison or diffing needs. its purpose is to compare two instances of `Nokogiri::XML::Node` or `Nokogiri::XML::NodeSet` for equality or equivalency.

**Features**

 - Fast, light-weight and highly customizable
 - Compares XML/HTML documents and document fragments
 - Can produce both detailed diffing discrepancies or execute silently
 - Has the ability to exclude specific nodes or attributes from all comparisons



## Installation

Add this line to your application's Gemfile:

    gem 'compare-xml'

And then execute:

    bundle

Or install it yourself as:

    gem install compare-xml



## Usage

Using CompareXML is as simple as

```ruby
CompareXML.equivalent?(doc1, doc2)
```

where `doc1` and `doc2` are instances of `Nokogiri::XML::Node` or `Nokogiri::XML::NodeSet`.

**Example**

Suppose you have two files `1.html` and `2.html` that you would like to compare. You could do it as follows:

```ruby
doc1 = Nokogiri::HTML(open('1.html'))
doc2 = Nokogiri::HTML(open('2.html'))
puts CompareXML.equivalent?(doc1, doc2)
```

The above code will print `true` or `false` depending on the result of the comparison.

> If you are using CompareXML in a script, then you need to require it manually with:

```ruby
require 'compare-xml'
```


## Options at a Glance

CompareXML has a variety of options that can be invoked as an optional argument, e.g.:

```ruby
CompareXML.equivalent?(doc1, doc2, {collapse_whitespace: false, verbose: true, ...})
```

- `collapse_whitespace: {true|false}` default: **`true`**&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[show examples ⇨](#collapse_whitespace)
    - when `true`, trims and collapses whitespace

- `ignore_attr_order: {true|false}` default: **`true`**&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[show examples ⇨](#ignore_attr_order)
    - when `true`, ignores attribute order within tags

- `ignore_attr_content: [string1, string2, ...]` default: **`[]`**&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[show examples ⇨](#ignore_attr_content)
    - when provided, ignores all attributes that contain substrings `string`, `string2`, etc.

- `ignore_attrs: [css_selector1, css_selector1, ...]` default: **`[]`**&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[show examples ⇨](#ignore_attrs)
    - when provided, ignores specific *attributes* using [CSS selectors](http://www.w3schools.com/cssref/css_selectors.asp)

- `ignore_attrs_by_name: [string1, string2, ...]` default: **`[]`**&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[show examples ⇨](#ignore_attrs_by_name)
    - when provided, ignores specific *attributes* using [String]

- `ignore_comments: {true|false}` default: **`true`**&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[show examples ⇨](#ignore_comments)
    - when `true`, ignores comments, such as `<!-- comment -->`

- `ignore_nodes: [css_selector1, css_selector1, ...]` default: **`[]`** &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[show examples ⇨](#ignore_nodes)
    - when provided, ignores specific *nodes* using [CSS selectors](http://www.w3schools.com/cssref/css_selectors.asp)

- `ignore_text_nodes: {true|false}` default: **`false`**&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[show examples ⇨](#ignore_text_nodes)
    - when `true`, ignores all text content within a document

- `verbose: {true|false}` default: **`false`**&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[show examples ⇨](#verbose)
    - when `true`, instead of a boolean, `CompareXML.equivalent?` returns an array of discrepancies.

- `ignore_children {true|false}` default **`false`**&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[show examples ⇨](#ignore_children)
    - when `true`, the subnodes of a node in the xml are ignored

- `force_children {true|false}` default **`false`**&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[show examples ⇨](#force_children)
    - when `true`, the subnodes of a node are checked independently of the status of the parent node


## Options in Depth

- <a id="collapse_whitespace"></a>`collapse_whitespace: {true|false}` default: **`true`**

    When `true`, all text content within the document is trimmed (i.e. space removed from left and right) and whitespace is collapsed (i.e. tabs, new lines, multiple whitespace characters are replaced by a single whitespace).

    **Usage Example:** `CompareXML.equivalent?(doc1, doc2, {collapse_whitespace: true})`

    **Example:** When `true` the following HTML strings are considered equal:

        <a href="/admin">   SOME TEXT CONTENT   </a>
        <a href="/index"> SOME    TEXT    CONTENT </a>

    **Example:** When `true` the following HTML strings are considered equal:

        <html>
            <title>
                This is my title
            </title>
        </html>

        <html><title>This is my title</title></html>


----------


- <a id="ignore_attr_order"></a>`ignore_attr_order: {true|false}` default: **`true`**

    When `true`, all attributes are sorted before comparison and only attributes of the same type are compared.

    **Usage Example:** `CompareXML.equivalent?(doc1, doc2, {ignore_attr_order: true})`

    **Example:** When `true` the following HTML strings are considered equal:

        <a href="/admin" class="button" target="_blank">Link</a>
        <a class="button" target="_blank" href="/admin">Link</a>

    **Example:** When `false` the above HTML strings are compared as follows:

        href="admin" != class="button

    The comparison of the `<a>` element will stop at this point, since a discrepancy is found.

    **Example:** When `true` the following HTML strings are compared as follows:

        <a href="/admin" class="button" target="_blank">Link</a>
        <a class="button" target="_blank" href="/admin" rel="nofollow">Link</a>

        class="button"  == class="button"
        href="/admin"   == href="/admin"
                        =! rel="nofollow"
        target="_blank" == target="_blank"


----------


- <a id="ignore_attr_content"></a>`ignore_attr_content: [string1, string2, ...]` default: **`[]`**

    When provided, ignores all **attributes** that contain any of the given substrings. **Note:** types of attributes still have to match (i.e. `<p>` = `<p>`, `<div>` = `<div>`,  etc).

    **Usage Example:** `CompareXML.equivalent?(doc1, doc2, {ignore_attr_content: ['button']})`

    **Example:** With `ignore_attr_content: ['button']` the following HTML strings are considered equal:

        <a href="/admin" id="button_1" class="blue button">Link</a>
        <a href="/admin" id="button_2" class="info button">Link</a>

    **Example:** With `ignore_attr_content: ['menu']` the following HTML strings are considered equal:

        <a class="menu left" data-scope="abrth$menu" role="side-menu">Link</a>
        <a class="main menu" data-scope="ergeh$menu" role="main-menu">Link</a>


----------


- <a id="ignore_attrs"></a>`ignore_attrs: [css_selector1, css_selector1, ...]` default: **`[]`**

    When provided, ignores all **attributes** that satisfy a particular rule using [CSS selectors](http://www.w3schools.com/cssref/css_selectors.asp).

    **Usage Example:** `CompareXML.equivalent?(doc1, doc2, {ignore_attrs: ['a[rel="nofollow"]', 'input[type="hidden"']})`

    **Example:** With `ignore_attrs: ['a[rel="nofollow"]', 'a[target]']` the following HTML strings are considered equal:

        <a href="/admin" class="button" target="_blank">Link</a>
        <a href="/admin" class="button" target="_self" rel="nofollow">Link</a>

     **Example:** With `ignore_attrs: ['a[href^="http"]', 'a[class*="button"]']` the following HTML strings are considered equal:

        <a href="http://google.ca" class="primary button">Link</a>
        <a href="https://google.com" class="primary button rounded">Link</a>

----------

- <a id="ignore_attrs_by_name"></a>`ignore_attrs_by_name: [string1, string2, ...]` default: **`false`**

    When provided, ignores all **attributes** which name is specified in the string array.

     **Usage Example:** `CompareXML.equivalent?(doc1, doc2, {ignore_attrs_by_name: ['target'])`

    **Example:** With `ignore_attrs_by_name: ['target', 'rel']` the following HTML strings are considered equal:

        <a href="/admin" class="button" target="_blank">Link</a>
        <a href="/admin" class="button" target="_self" rel="nofollow">Link</a>

----------


- <a id="ignore_comments"></a>`ignore_comments: {true|false}` default: **`true`**

    When `true`, ignores comments, such as `<!-- This is a comment -->`.

    **Usage Example:** `CompareXML.equivalent?(doc1, doc2, {ignore_comments: true})`

    **Example:** When `true` the following HTML strings are considered equal:

        <!-- This is a comment -->
        <!-- This is another comment -->

    **Example:** When `true` the following HTML strings are considered equal:

        <a href="/admin"><!-- This is a comment -->Link</a>
        <a href="/admin">Link</a>


----------


- <a id="ignore_nodes"></a>`ignore_nodes: [css_selector1, css_selector1, ...]` default: **`[]`**

    When provided, ignores all **nodes** that satisfy a particular rule using [CSS selectors](http://www.w3schools.com/cssref/css_selectors.asp).

    **Usage Example:** `CompareXML.equivalent?(doc1, doc2, {ignore_nodes: ['script', 'object']})`

    **Example:** With `ignore_nodes: ['a[rel="nofollow"]', 'a[target]']` the following HTML strings are considered equal:

        <a href="/admin" class="icon" target="_blank">Link 1</a>
        <a href="/index" class="button" target="_self" rel="nofollow">Link 2</a>

     **Example:** With `ignore_nodes: ['b', 'i']` the following HTML strings are considered equal:

        <a href="/admin"><i class"icon bulb"></i><b>Warning:</b> Link</a>
        <a href="/admin"><i class"icon info"></i><b>Message:</b> Link</a>


----------


- <a id="ignore_text_nodes"></a>`ignore_text_nodes: {true|false}` default: **`false`**

    When `true`, ignores all text content. Text content is anything that is included between an opening and a closing tag, e.g. `<tag>THIS IS TEXT CONTENT</tag>`.

    **Usage Example:** `CompareXML.equivalent?(doc1, doc2, {ignore_text_nodes: true})`

    **Example:** When `true` the following HTML strings are considered equal:

        <a href="/admin">SOME TEXT CONTENT</a>
        <a href="/admin">DIFFERENT TEXT CONTENT</a>

    **Example:** When `true` the following HTML strings are considered equal:

        <i class="icon></i>  <b>Warning:</b>
        <i class="icon>  </i>    <b>Message:</b>


----------


- <a id="verbose"></a>`verbose: {true|false}` default: **`false`**

    When `true`, instead of returning a boolean value  `CompareXML.equivalent?` returns an array of all errors encountered when performing a comparison.

    > **Warning:** When `true`, the comparison takes longer! Not only because more processing is required to produce meaningful differences, but also because in this mode, comparison does **NOT** stop when a first difference is encountered, because the goal is to capture as many differences as possible.

    **Usage Example:** `CompareXML.equivalent?(doc1, doc2, {verbose: true})`

    **Example:** When `true` given the following HTML strings:

    ![diffing](https://github.com/vkononov/compare-xml/raw/master/img/diffing.png)

    `CompareXML.equivalent?(doc1, doc2, {verbose: true})` will produce an array shown below.

    ```ruby
    [
        {
            node1: '<title>TITLE</title>',
            node2: '<title>ANOTHER TITLE</title>',
            diff1: 'TITLE',
            diff2: 'ANOTHER TITLE',
        },
        {
            node1: '<h1>SOME HEADING</h1>',
            node2: '<h1 id="main">SOME HEADING</h1>',
            diff1: nil,
            diff2: 'id="main"',
        },
        {
            node1: '<a href="/admin" rel="icon">Link</a>',
            node2: '<a rel="button" href="/admin">Link</a>',
            diff1: '"rel="icon"',
            diff2: '"rel="button"',
        },
        {
            node1: '<cite>Author Name</cite>',
            node2: nil,
            diff1: '<cite>Author Name</cite>',
            diff2: nil,
        },
        {
            node1: '<p class="footer">FOOTER</p>',
            node2: '<div class="footer">FOOTER</div>',
            diff1: 'p',
            diff2: 'div',
        }
    ]
    ```

    The structure of each hash inside the array is:

        node1: [Nokogiri::XML::Node] left node that contains the difference
        node2: [Nokogiri::XML::Node] right node that contains the difference
        diff1: [Nokogiri::XML::Node|String] left difference
        diff2: [Nokogiri::XML::Node|String] right difference

----------

- <a id="ignore_children"></a>`ignore_children: {true|false}` default: **`false`**

    When provided, ignores all **subnodes** of any node.

    **Usage Example:** `CompareXML.equivalent?(doc1, doc2, {ignore_children: true})`

    **Example:** With `ignore_children: true` the following HTML strings are considered equal:

        <body><a href="/admin" class="icon" target="_blank">Link 1</a></body>
        <body><a href="/index" class="button" target="_self" rel="nofollow">Link 2</a></body>

----------

- <a id="force_children"></a>`force_children: {true|false}` default: **`false`**

    When provided, compares all **subnodes** of any node.

    **Usage Example:** `CompareXML.equivalent?(doc1, doc2, {ignore_children: true})`

----------

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request



## Credits

This gem was inspired by [Michael B. Klein](https://github.com/mbklein)'s gem [`equivalent-xml`](https://github.com/mbklein/equivalent-xml) - another excellent tool for XML comparison.



## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).