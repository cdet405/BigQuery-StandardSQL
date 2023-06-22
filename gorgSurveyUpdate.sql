-- set blanks to null
update manifest.gorgSurvey
set body_text = null,
mod_date = current_date()
where length(body_text)=0
