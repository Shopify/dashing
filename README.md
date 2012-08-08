# Dashing!

A handsome dashboard framework solution

## Introduction

Dashing is a framework for building web-based dashboards.

Features:

 - Custom widgets! Built using whatever HTML/Coffeescript wizardry you posses
 - Multiple dashboards! You can have many different views all hosted in the same location
 - Shared widgets! It's easy to have have the same widget show up on different dashboards
 - Push or pull data, you decide!
 - Responsive grid layout! Your dashboard will look good on any sized screen

## Installation and Setup

  1. Install the gem from the command line:

    ```gem install dashing```

  2. Generate a new project:

    ```dashing new sweet_dashboard_project```

  3. Change your directory to ```sweet_dashboard_project``` and start Dashing

    ```dashing start```

  4. Point your browser at [localhost:3000](http://localhost:3000)

## Building a dashboard

```main.erb``` contains the layout for the default dashboard which is accessible at ```/```.
You can add additional dashboards with by running ```dashing COMMAND THINGY new_view``` which creates a ```new_view.erb``` file in ```dashboards/```.
That new view will be accessible at ```localhost:3000/new_view```

## Widgets

Widgets are represented by a ```div``` element with ```data-id``` and ```data-view``` attributes. eg:

```HTML
<div data-id="sample" data-view="SweetWidget"></div>
```

The ```data-id``` attribute is used to set the **widget ID** which will be used when to push data to the widget. Two widgets can have the same widget id, allowing you to have the same widget in multiple dashboards.

```data-view``` specifies the type of widget what will be used. This field is case sensitive and must match the coffeescript class of the widget. See making your own widget section for more details.

This ```<div>``` can also be used to configure your widgets. For example, the pre-bundled widgets let you set a title with ```data-title="Widget Title"```.

### Layout

Getting the style and layout right when you have multiple widgets is hard, that's why we've done it for you. By default Dashing uses [masonry](http://masonry.desandro.com/) to produce a grid layout. If it can, your dashboard will fill the screen with 5 columns. If there isn't enough room though, widgets will be reorganized to fit into fewer columns until you are left with a single column

Examples here?

Masonry requires that your widgets be contained within a ```<ul>``` element as follows:

```HTML
<ul class="list-nostyle clearfix">
  <li class="widget-container">
    <div data-id="widget_id1" data-view="MyWidget"></div>
  </li>
  <li class="widget-container">
    <div data-id="widget_id2" data-view="MyWidget"></div>
  </li>
  <li class="widget-container">
    <div data-id="widget_id3" data-view="MyWidget"></div>
  </li>
</ul>
```

### Making you own widget

A widget consists of three parts:

 - an html file used for layout and bindings
 - a scss file for style
 - a coffeescript file which allows you to operate on the data

To make your own run ```dashing generate sweet_widget``` which will create scaffolding files in the ```widget/``` folder or your project.

#### sweet_widget.html

Contains the HTML for you widget.
We use [batman bindings](http://batmanjs.org/docs/batman.html#batman-view-bindings-how-to-use-bindings) in order to update the content of a widget.
In the example below, updating the title attribute of the coffeescript object representing that widget will set the innerHTML of the ```<h1>``` element.
Dashing provides a simple way to update your widgets attributes through a push interface and a pull interface. See the Getting Data into Dashing section.

##### Example
```html
<h1 data-bind="title"></h1>

<h3 data-bind="text"></h3>
````

#### sweet_widget.coffee

This coffee script file allows you to perform any operations you wish on your widget. In the example below we can initialize things with the constructor method.
We can also manipulate the data we recieve from data updates. Data will be the JSON object you pass in.

##### Example
```coffeescript
class Dashing.SweetWidget extends Dashing.Widget

  constructor: ->
    super
    @set('attr', 'wooo')

  onData: (data) ->
    super
    @set('cool_thing', data.massage.split(',')[2]
```

#### sweet_widget.scss

##### Example
````scss
$text_value-color:       #fff;
$text_title-color:       lighten($widget-text-color, 30%);

.widget-text {
  .title {
    color: $text_title-color;
  }
  .p {
    color: $text_value-color:
  }
}
```

## Getting data into Dashing

Providing data to widgets is easy. You specify which widget you want using a widget id. Dashing expects the data you send to be in JSON format.
Upon getting data, dashing mixes the json into the widget object. So it's easy to update multiple attributes within the same object.

### Jobs (poll)

Dashing uses [rufus-scheduler](http://rufus.rubyforge.org/rufus-scheduler/) to schedule jobs.
You can make a new job with ```dashing job super_job``` which will create a file in the jobs folder called ```super_job.rb```.
Data is sent to a widget using the ```send_event(widget_id, json_formatted_data)``` method.

#### Example

```ruby
# :first_in sets how long it takes before the job is first run. In this case, it is run immediately
SCHEDULER.every '1m', :first_in => 0 do |job|
  send_event('widget_id', {text: "I am #{%w(happy sad hungry).sample}"})
end
```

### Push

You can also push data directly to your dashboard! Post the data you want in json to ```/widgets/widget_id```.
For security, you will also have to include your auth_token (which can be found in ```config.ru```) as part of the json object.

#### Example
```bash
curl -d '{ "auth_token": "YOUR_AUTH_TOKEN", "value": 100 }' http://localhost:3000/widgets/synergy
```

or

```ruby
HTTParty.post('http://ADDRESS/widgets/widget_id',
  :body => { auth_token: "YOUR_AUTH_TOKEN", text: "Weeeeee"}.to_json)
```

## Misc

### Deploying to heroku

### Using omni-auth

## Dependencies

 - [Sinatra](http://www.sinatrarb.com/)
 - [batman.js](http://batmanjs.org/)
 - [rufus-scheduler](http://rufus.rubyforge.org/rufus-scheduler/)
 - [Thor](https://github.com/wycats/thor/)
 - [jQuery-knob](http://anthonyterrien.com/knob/)
 - [masonry](http://masonry.desandro.com/)
 - [thin](http://code.macournoyer.com/thin/)
 - [Sass](http://sass-lang.com/)

## Licensing

This code is released under the MIT license. See ```MIT-LICENSE``` file for more details