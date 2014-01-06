
<nav class="navbar navbar-inverse navbar-fixed-top">

    <div class="navbar-header">
        <button type="button" class="navbar-toggle" data-toggle="collapse" data-target=".navbar-collapse">
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
        </button>

        <a class="navbar-brand" href="/" title="{_ visit site _}"><img alt="zotonic logo" src="/lib/images/admin_zotonic.png" width="106" height="20"></a>
    </div>

        <div class="collapse navbar-collapse">
            {% block search %}
            <form class="navbar-right navbar-form form-search" action="{% block search_target %}{% url admin_overview_rsc %}{% endblock %}" method="get" role="search">
                    <input type="hidden" name="qsort" value="{{ q.qsort|escape }}" />
                    <input type="hidden" name="qcat" value="{{ q.qcat|escape }}" />
                    <input class="form-control search-query" type="text" name="qs" value="{{q.qs|escape}}" placeholder="Search..." />
            </form>
            {% endblock %}

            <ul class="nav navbar-nav">
                {% for id, item in m.admin_menu %}
                    {% if item.items %}
                    <li class="dropdown" id="nav-{{ id }}">
                        <a class="dropdown-toggle" data-toggle="dropdown" href="#nav-{{ id }}">
                            {% if item.icon %}<i class="icon-{{ item.icon }} icon-white"></i>{% endif %}
                            {{ item.label|escape }}
                            <b class="caret"></b>
                        </a>
                        <ul class="dropdown-menu">
                        {% for id, item in item.items %}
                            {% if item.separator %}
                            <li class="divider"></li>
                            {% else %}
                            <li><a href="{{ item.url }}">
                                {% if item.icon %}<i class="icon-{{ item.icon }}"></i>{% endif %}
                                {{ item.label|escape }}</a>
                            </li>
                            {% endif %}
                        {% endfor %}
                        </ul>
                    </li>
                    {% else %}
                    <li class="">
                        <a href="{{ item.url }}">{{ item.label|escape }}</a>
                    </li>
                    {% endif %}
                {% endfor %}
                <li>
                    <a href="#" id="{{ #logoff }}" title="{_ Log Off _}"><span class="glyphicon glyphicon-off icon-white"></span></a>
                    {% wire id=#logoff action={confirm title=_"Confirm logoff" text=_"Are you sure you want to exit the admin interface?"
                                               action={redirect dispatch=`logoff`}} %}
                </li>
            </ul>

            <ul class="nav navbar-nav navbar-right">
                {% all include "_admin_headeritem.tpl" %}
            </ul>

        </div>
            
</nav>
