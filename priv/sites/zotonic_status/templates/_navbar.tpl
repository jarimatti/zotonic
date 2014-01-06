<div class="navbar navbar-default navbar-fixed-top">
    <div class="navbar-header">
        <button type="button" class="navbar-toggle" data-toggle="collapse" data-target="#status-site-navbar">
            <span class="sr-only">Toggle navigation</span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
        </button>
        <a class="navbar-brand" href="http://{{ m.site.hostname }}" title="{_ visit site _}"><img alt="zotonic logo" src="/lib/images/zotonic_gray.png" width="106" height="20"></a>
    </div>

    <div class="collapse navbar-collapse navbar-right" id="status-site-navbar">
        <ul class="nav navbar-nav">

            {% if m.acl.user %}
            <li{% if zotonic_dispatch == "home" %} class="active"{% endif %}>
                <a href="{% url home %}">{_ Sites _}</a>
            </li>

	    <li><a id="{{ #logoff }}" href="#logoff">{_ Log Off _}</a>
            </li>
	    {% wire id=#logoff postback={logoff} %}
            {% endif %}
        </ul>
    </div>
</div>
