<div class="form-group">
	<label class="col-sm-3 control-label" for="email">{_ E-mail address _}</label>
	<div class="col-sm-9">
		<input id="email" type="text" name="email" value="{{ id.email }}" class="form-control" />
		{% validate id="email" type={email} %}
	</div>
</div>
