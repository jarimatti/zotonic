{% block question_page %}
	{% if page_nr == 1 and id.survey_is_autostart %}
		{% block autostart_body %}
			{% include "_survey_autostart_body.tpl" %}
		{% endblock %}
	{% endif %}

	{% wire id=#q type="submit"
		postback={survey_next id=id page_nr=page_nr answers=answers history=history editing=editing element_id=element_id|default:"survey-question"}
		delegate="mod_survey"
	%}
	<form class="form-survey survey-{{ id.name }}" id="{{ #q }}" method="post" action="postback">
		<fieldset>
			{% if not id.is_a.poll and pages > 1 %}
				{% if id.survey_progress == 'nr' %}
					<legend>{{ page_nr }}<span class="total">/{{ pages }}</span></legend>
				{% elseif id.survey_progress == 'bar' %}
					<div class="progress">
					  <div class="progress-bar" style="width: {{ page_nr * 100 / pages }}%;"></div>
					</div>
				{% endif %}
			{% endif %}

			{% for blk in questions %}
				{% optional include ["blocks/_block_view_",blk.type,".tpl"]|join id=id blk=blk answers=answers nr=forloop.counter %}
			{% endfor %}
		</fieldset>

		{% if not editing %}
			<div class="alert alert-danger z_invalid">
				{_ Please fill in all the required fields. _}
			</div>
		{% endif %}

		{% if editing and pages == 1 %}
			<div class="modal-footer">
		{% else %}
			<div class="form-actions">
		{% endif %}

			{% if page_nr > 1 %}
				<a id="{{ #back }}" href="#" class="btn btn-default">{_ Back _}</a>
				{% wire id=#back
						postback={survey_back id=id page_nr=page_nr answers=answers history=history editing=editing element_id=element_id|default:"survey-question"}
						delegate="mod_survey"
				%}
			{% endif %}

			{% if not editing or pages > 1 %}
				{% if not id.survey_is_autostart or page_nr > 1 %}
					<a id="{{ #cancel }}" href="#" class="btn btn-default">{_ Stop _}</a>
					{% wire id=#cancel action={confirm text=_"Are you sure you want to stop?" ok=_"Stop" cancel=_"Continue" action={redirect id=id}} %}
				{% endif %}
			{% else %}
				<a id="{{ #cancel }}" href="#" class="btn btn-default">{_ Cancel _}</a>
				{% wire id=#cancel action={dialog_close} %}
			{% endif %}

			{% if editing %}
				<button type="submit" class="btn btn-primary">{% if page_nr == pages %}{_ Submit _}{% else %}{_ Next _}{% endif %}</button>
			{% else %}
				{% with questions|last as last_q %}
					{% if not editing and not questions|survey_is_submit and last_q.type /= "survey_stop" %}
						<button type="submit" class="btn btn-primary">{% if page_nr == pages %}{_ Submit _}{% else %}{_ Next _}{% endif %}</button>
					{% endif %}
				{% endwith %}
			{% endif %}
		</div>
	</form>
	{% javascript %}
		$('body').removeClass('survey-start').addClass('survey-question');

		var pos = $('#{{ #q }}').position();
		if (pos.top < $(window).scrollTop() + 100) {
			$(window).scrollTop(pos+100);
		}
	{% endjavascript %}

	{% if page_nr == 1 and id.survey_is_autostart %}
		{% block autostart_footer %}
			{% include "_survey_autostart_footer.tpl" %}
		{% endblock %}
	{% endif %}
{% endblock %}

{% block question_page_after %}
{% endblock %}
