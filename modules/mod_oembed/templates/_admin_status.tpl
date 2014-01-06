{% if m.acl.use.mod_oembed %}
<div class="form-group">
    {% button class="btn btn-default" text=_"Fix embedded videos" postback="fix_missing" delegate=`mod_oembed` %} 
    <span class="help-inline">{_ Attempt to fix embedded videos for which OEmbed embedding has failed previously. _}</span>
</div>
{% endif %}
