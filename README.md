# Dashing!

<!-- CI status? -->

## Introduction

Dashing is a framework for building web-based dashboards.

Features:

 - Custom widgets! Built using whatever HTML/Coffeescript wizardry you posses
 - Multiple dashboards! You can have many different views all hosted by the same app
 - Shareable widgets!
 - ...

## Installation and Setup

  1. Install the gem from the command line:

    ```gem install dashing```

  2. Generate a new project:

    ```dashing new sweet_dashboard_project```

  3. Change your directory to ```sweet_dashboard_project``` and start the Dashing

    ```dashing start```

  4. Point your browser at [localhost:3000](http://localhost:3000)

## Building a dashboard

```main.erb``` contains the layout for the default dashboard which is accessible at ```/```. You can add additional dashboards with ```COMMAND new_view``` which creates a ```new_view.erb``` file in ```dashboards/```. That new view will be accessible at ```localhost:3000/new_view```

Widgets are represented by a ```div``` with ```data-id``` and ```data-view``` attributes. For example:

```HTML
<div data-id="sample" data-view="SweetWidget"></div>
```

represents a dashboard with a single widget.

The ```data-id``` is used to set the widget_id which will be used when we push data to the widget. widget_ids can be shared across dashboards.

```data-view``` specifies the type of widget what will be used. This field is case sensitive and must match the name of coffeescript class. See making your own widget.

Getting the style and layout right when you have multiple widgets is hard, that's why we've done it for you. By default Dashing uses [masonry](http://masonry.desandro.com/) to produce a grid layout.

#### Example
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

## Making you own widget

To make your own run ```dashing generate sweet_widget``` which will create template files in the ```widget/``` folder or your project.

### sweet_widget.html

Contains the HTML for you widget.

#### Example
```html
<h1 data-bind="title"></h1>

<h3 data-bind="text"></h3>
````

### sweet_widget.coffee

#### Example
```coffeescript
class Dashing.SweetWidget extends Dashing.Widget
  source: 'widget_text'

  onData(data) ->
    #stuff?
```

### sweet_widget.scss
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

### Jobs

Dashing uses [rufus-scheduler](http://rufus.rubyforge.org/rufus-scheduler/) to schedule jobs. You can make a new job with ```things job super_job``` which will create a file in the jobs folder called ```super_job.rb```.

Use ```send_event('WIDGET_ID', {text: SAMPLE_DATUMS})```

#### Example

```ruby
# :first_in sets how long it takes before the job is first run. In this case, it is run immediately
SCHEDULER.every '1m', :first_in => 0 do |job|
  send_event('widget_id', {text: "I am #{%w(happy sad hungry).sample}"})
end
```

### Push

You can also push data directly to your dashboard! Post the data you want in json to ```/widgets/widget_id```. You will also have to include your auth_token (which can be found in ```config.ru```) as part of the json object.

#### Example
```bash
curl -d '{ "auth_token": "YOUR_AUTH_TOKEN", "value": 100 }' http://localhost:3000/widgets/synergy
```

or

```ruby
HTTParty.post('http://ADDRESS/widgets/widget_id',
  :body => {
    auth_token: "YOUR_AUTH_TOKEN",
    text: "Weeeeee",
  }.to_json)
```

## Licensing

This code is released under the MIT license. Please read the MIT-LICENSE file for more details

TODO
====

- tests
- investigate if Dir.pwd is the best approach to get the local directory
- Create githubpages
- Open source!
