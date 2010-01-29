# Config Assistant, a plugin for Movable Type #

_**Note to Melody users:** This plugin's functionality is already core in
Melody so separate installation is neither required nor advisable._

This plugin allows theme and plugin developers to easily surface a form 
within Movable Type for configuring their theme/plugin. In addition, it allows
theme and plugin developers to define template tags by which they can access
the values entered in by their users directly within their templates.

All this **without having to know perl or how to program at all**!

This plugin works by allowing a developer to use their plugin's configuration
file as a means for defining what the various settings and form elements they
would like to expose to a user.

If Config Assistant is being used within the context of a theme, then users of 
your theme will automatically have a "Theme Options" menu item added to their 
design menu so they can easily access the settings you define.

The sample config file below should give you a quick understanding of how you
can begin using this plugin today.

## Prerequisites ##

* Movable Type 4.1 or higher

## Installation ##

The latest version of the plugin can be downloaded from [its GitHub repo](http://github.com/endevver/mt-plugin-configassistant):

&nbsp;&nbsp;[http://github.com/endevver/mt-plugin-configassistant/downloads](http://github.com/endevver/mt-plugin-configassistant/downloads)

It is installed [just like any normal Movable Type Plugin](http://www.majordojo.com/2008/12/the-ultimate-guide-to-installing-movable-type-plugins.php).

## Reference and Documentation ##

### Using Config Assistant for Theme Options ###

This plugin adds support for a new element in any plugin's `config.yaml` file called
`options`, which is placed as a descendant to a defined template set. When a user of 
your plugin applies the corresponding template set then a "Theme Options" menu item
will automatically appear in their "Design" menu. They can click that menu item to 
be taken directly to a page on which they can edit all of their theme's settings.

    name: My Plugin
    id: MyPlugin
    template_sets:
        my_awesome_theme:
            options:
                fieldsets:
                    homepage:
                        label: 'Homepage Options'
                    feed:
                        label: 'Feed Options'
                feedburner_id:
                    type: text
                    label: "Feedburner ID"
                    hint: "This is the name of your Feedburner feed."
                    tag: 'MyPluginFeedburnerID'
                    fieldset: feed
                use_feedburner:
                    type: checkbox
                    label: "Use Feedburner?"
                    tag: 'IfFeedburner?'
                    fieldset: feed
                posts_for_frontfoor:
                    type: text
                    label: "Entries on Frontdoor"
                    hint: 'The number of entries to show on the front door.'
                    tag: 'FrontdoorEntryCount'
                    fieldset: homepage
                    condition: > 
                      sub { return 1; }

### Using Config Assistant for Plugin Settings ###

To use Config Assistant as the rendering and enablement platform for plugin
settings, use the same `options` struct you would for theme options, but use
it as a root level element. For example:

    name: My Plugin
    id: MyPlugin
    options:
      fieldsets:
        homepage:
          label: 'Homepage Options'
        feed:
          label: 'Feed Options'
      feedburner_id:
        type: text
        label: "Feedburner ID"
        hint: "This is the name of your Feedburner feed."
        tag: 'MyPluginFeedburnerID'
        fieldset: feed

Using this method for plugin options completely obviates the need for developers 
to specify the following elements in their plugin's config.yaml files:

* `settings`
* `blog_config_template`
* `system_config_template`

### Fields ###

Each field definition supports the following properties:

* `type` - the type of the field. Supported values are: text, textarea, select,
  checkbox, blogs
* `label` - the label to display to the left of the input element
* `show_label` - display the label? (default: yes). This is ideal for checkboxes.
* `hint` - the hint text to display below the input element
* `tag` - the template tag that will access the value held by the corresponding
  input element
* `condition` - a code reference that will determine if an option is rendered
  to the screen or not. The handler should return true to show the option, or false
  to hide it.
* `default` - a static value or a code reference which will determine the proper
   default value for the option
* `order` - the sort order for the field within its fieldset
* `republish` - a list of template identifiers (delimitted by a comma) that reference
  templates that should be rebuilt when a theme option changes
* `scope` - (for plugin settings only, all theme options are required to be
  blog specific) determines whether the config option will be rendered at the blog
  level or system level.

#### Supported Field Types ####

Below is a list of acceptable values for the `type` parameter for any defined 
field:

* `text` - Produces a simple single line text box.

* `textarea` - Produces a multi-line text box. You can specify the `rows` sibling 
  element to control the size/height of the text box.

* `select` - Produces a pull-down menu or arbitrary values. Those values are
  defined by specifying a sibling element called `values` which should contain 
  a comma delimitted list of values to present in the pull down menu

* `checkbox` - Produces a single checkbox, ideal for boolean values.

* `blogs` - Produces a pull down menu listing every blog in the system.
  *Warning: this is not advisable for large installations as it can dramatically
  impact performance (negatively).*

* `radio-image` - Produces a javascript enabled list of radio buttons where 
  each "button" is an image. Note that this version of the radio type supports
  a special syntax for the `values` attribute. See example below.

* `tagged-entries` - Produces a pull down menu of entries tagged a certain way.
  This type supports the following additional attributes: `lastn` and `tag-filter`.

* `entry` - Produces the ability to select a single entry via a small pop-up 
  dialog. In the dialog, the user will be permitted to search the system via
  keyword for the entry they are looking for. This field type supports the 
  field property of `all_blogs`, a boolean value which determines whether the 
  user will be constricted to searching entries in the current blog, or all
  blogs on the system.

* `colorpicker` - Produces a color wheel pop-up for selecting a color or hex value.

**Example Radio Image**

The `radio-image` type supports a special syntax for the `values` attribute which
allows you to associate an image with each choice:

    values: "IMGRELPATH":"LABEL", "IMGRELPATH2":"LABEL2"

In the above, each `IMGRELPATH` represents the path to an image relative to Movable
Type's mt-static directory and each `LABEL` is the accompanying label for the option.
The path and label are separated by a colon and each combined value is separated by
a comma.

For example, `radio-images` defining a homepage layout for a plugin `Foo` might look
like this:

      homepage_layout:
        type: radio-image
        label: 'Homepage Layout'
        hint: 'The layout for the homepage of your blog.'
        tag: 'HomepageLayout'
        values: "plugins/Foo/layout-1.png":"Layout 1","plugins/Foo/layout-2.png":"Layout 2"

The above will present the user with two radio buttons labelled Layout 1 and Layout 2 
accompanied by a representative image demonstrating each option.

_FIXME: Insert screenshot_

#### Defining Custom Field Types ####

To define your own form field type, you first need to register your type and 
type handler in your plugin's `config.yaml` file, like so:

    config_types:
      my_custom_type:
        handler: $MyPlugin::MyPlugin::custom_type_hdlr

Then in `plugins/MyPlugin/lib/MyPlugin.pm` you would implement your handler.
Here is an example handler that outputs the HTML for a HTML pulldown or select
menu:

    sub custom_type_hdlr {
      my $app = shift;
      my ($field_id, $field, $value) = @_;
      my @values = split( ",", $field->{values} );
      my $class  = 'class="rb"';
      my $type   = 'type="radio"';
      my @options;
      foreach my $opt (@values) {
          my $checked = $opt eq $value ? " checked=\"checked\"" : "";
          push( @options, qq(
            <input $type name="$field_id" value="$opt" $checked $class /> $opt
          ));
      }
      return '<ul><li>', join("</li>\n<li>", @options), '</li></ul>';
    }

With these two tasks complete, you can now use your new config type in your template set:

    template_sets:
      my_theme:
        label: 'My Theme'
        options:
          layout:
            type: my_custom_type
            values: foo,bar,baz
            label: 'My Setting'
            default: 'bar'

### Defining Template Tags ###

Each plugin configuration field can define a template tag by which a designer
or developer can access its value. If a tag name terminates in a question mark
then the system will interpret the tag as a conditional block element. Here are 
two example fields:

    feedburner_id:
        type: text
        label: "Feedburner ID"
        hint: "This is the name of your Feedburner feed."
        tag: 'FeedburnerID'
    use_feedburner:
        type: checkbox
        label: "Use Feedburner?"
        tag: 'IfFeedburner?'

And here are corresponding template tags that make use of these configuration
options:

    <mt:IfFeedburner>
      My feedburner id is <$mt:FeedburnerID$>.
    <mt:Else>
      Feedburner is disabled!
    </mt:IfFeedburner>

### Callbacks ###

Config Assistant supports a number of callbacks to give developers the ability
to respond to specific change events for options at a theme and plugin level.
All of these callbacks are in the `options_change` callback family.

#### On Single Option Change ####

Config Assistant defines a callback which can be
triggered when a specific theme option changes value or when any theme option 
changes value. To register a callback for a specific theme option, you would use
the following syntax:

    callbacks:
      options_change.option.<option_id>: $MyPlugin::MyPlugin::handler

To register a callback to be triggered when *any* theme option changes, you would 
use this syntax:

    callbacks:
      options_change.option.*: $MyPlugin::MyPlugin::handler

When the callback is invoked, it will be invoked with the following input parameters:

* `$cb` - The MT::Callback object for the current callback.
* `$app` - An object instance for the currently running app, most likely an
  MT::App subclass.
* `$option_hash` - A reference to a hash containing the name/value pairs representing
  this modified theme option in the registry.
* `$old_value` - The value of the option prior to being modified.
* `$new_value` - The value of the option after being modified.

**Example**

    sub my_handler {
      my ($cb, $app, $option_hash, $old_value, $new_value) = @_;
      MT->log({
          message =>   "Changing "
                     . $option_hash->{label}
                     . " from $old_value to $new_value."
      });
    }

**Note: The callback is invoked after the new value has been inserted into the config
hash, but prior to the hash being saved. This gives developers the opportunity to change
the value of the config value one last time before being committed to the database.**

#### On Plugin Option Change ####

Config Assistat has the ability to trigger a callback when any option within a 
plugin changes. To register a callback of this nature you would use the following
syntax replacing `<plugin_id>` with your plugin's `id` attribute value and `<handler>`
with a typical handler reference:

    callbacks:
      options_change.plugin.<plugin_id>: <handler>

For example:

    callbacks:
      options_change.plugin.MyPlugin: $MyPlugin::MyPlugin::handler

When the callback is invoked, it will be invoked with the following input parameters:

* `$cb` - The MT::Callback object for the current callback.
* `$app` - An object instance for the currently running app, most likely an MT::App
subclass.
* `$plugin` - A reference to the plugin object that was changed

_FIXME: Does $plugin refer to an MT::Plugin or MT::PluginSettings object?  The
former is unnecessary as you can get the same thing from `$cb->plugin`.  It seems
like we should be passing the full options hashref as well as a "changed values"
hashref._

## Support ##

http://forums.movabletype.org/codesixapartcom/project-support/

FIXME: Lighthouse project?

## Info ##

This plugin is not necessary in Melody, as this is core component of that platform.

Configuration Assistant Plugin for Movable Type and Melody
Author: Byrne Reese   
Copyright 2008 Six Apart, Ltd.   
Copyright 2009 Byrne Reese   
License: Artistic, licensed under the same terms as Perl itself   

