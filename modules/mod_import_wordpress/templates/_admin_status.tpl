{% if m.acl.use.mod_import_wordpress %}
<div class="form-group">
    {% button class="btn btn-default" text=_"Wordpress import" action={dialog_open title=_"Import WXR file" template="_dialog_import_wordpress.tpl"} %} 
    <span>{_ Import a Wordpress WXR export file into Zotonic. _}</span>
</div>
{% endif %}
