<div class="form-group">
    {% button class="btn btn-default" text=_"Rescan modules" action={module_rescan} %}
    <span class="help-inline">{_ Rescanning will rebuild the index of all modules, actions, templates etc.  It will also reload all dispatch rules. _}</span>
</div>
