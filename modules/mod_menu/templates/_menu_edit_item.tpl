{% if id %}<li id="{{ #menu.c }}-{{ id }}" class="menu-item">
	<div id="{{ menu_id|default:#menu.id }}" data-page-id="{{ id }}">
	    <img class="grippy" src="/lib/images/grippy.png" title="{_ Drag me _}" />
	    <span class="title-{{id}}">{{ id.short_title|default:id.title }}</span>

		<span class="warning glyphicon glyphicon-eye-close" {% if id.is_published %}style="display: none"{% endif %}></span>

	    <span class="btns">
		    <span class="btn-group">
		        <a href="#" class="btn btn-default btn-xs menu-edit">{_ Edit _}</a>
		    </span>

		    <span class="btn-group">
		        <a href="#" class="btn btn-default btn-xs dropdown-toggle" data-toggle="dropdown"><span class="glyphicon glyphicon-cog"></span> <span class="caret"></span></a>
				<ul class="dropdown-menu">
				    <li><a href="#" data-where="before">&uarr; {_ Add before _}</a></li>
				    <li><a href="#" data-where="below">&rarr; {_ Add below _}</a></li>
				    <li><a href="#" data-where="after">&darr; {_ Add after _}</a></li>
				    <li class="divider"></li>
				    <li><a href="#" data-where="copy">{_ Copy _}</a></li>
				    {% if not id.is_protected %}
				    <li><a href="#" data-where="remove">{_ Remove _}</a></li>
				    {% endif %}
				</ul>
		    </span>
		  </span>
	</div>

	{% if action == `down` %}
		<ul class="menu-submenu">
	{% else %}
		</li>
	{% endif %}
{% else %}
</ul></li>{% endif %}