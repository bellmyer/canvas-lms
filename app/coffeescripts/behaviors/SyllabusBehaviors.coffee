#
# Copyright (C) 2013 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

define [
  'jquery' # jQuery, $ #
  'calendar_move' # calendarMonths #
  'jsx/shared/rce/RichContentEditor'
  'compiled/views/editor/KeyboardShortcuts'
  'jquery.instructure_date_and_time' # dateString, datepicker #
  'jquery.instructure_forms' # formSubmit, formErrors #
  'jquery.instructure_misc_helpers' # scrollSidebar #
  'jquery.instructure_misc_plugins' # ifExists, showIf #
  'jquery.loadingImg' # loadingImage #
  'vendor/jquery.scrollTo' # /\.scrollTo/ #
  'jqueryui/datepicker' # /\.datepicker/ #
], ($, calendarMonths, RichContentEditor, KeyboardShortcuts) ->

  specialDatesAreHidden = false

  RichContentEditor.preloadRemoteModule()


  # Highlight mini calendar days matching syllabus events
  #    Queries the syllabus event list and highlights the
  #    corresponding mini calendar dates.
  highlightDaysWithEvents = ->
    $mini_month = $('.mini_month')
    $syllabus = $('#syllabus')
    if !$mini_month or !$syllabus
      return

    $mini_month.find('.day.has_event').removeClass 'has_event'

    $syllabus.find('tr.date:visible').each ->
      date = $(this).find('.day_date').attr('data-date')
      $mini_month.find("#mini_day_#{date}").addClass 'has_event'

  # Sets highlighting on a given date
  #    Removes all highlighting then highlights the given
  #    date, if provided.
  highlightDate = (date) ->
    $mini_month = $('.mini_month')
    $syllabus = $('#syllabus')

    $('tr.date.related, .day.related').removeClass('related')
    if date
      $mini_month.find("#mini_day_#{date}").addClass('related') if $mini_month
      $syllabus.find("tr.date.events_#{date}").addClass('related') if $syllabus

  highlightRelated = (related_id, self) ->
    $syllabus = $('#syllabus')

    $syllabus.find('.detail_list tr.related_event').removeClass('related_event')
    if related_id and $syllabus
      $(rel).addClass('related_event') for rel in $syllabus.find(".detail_list tr.related-#{related_id}") when rel != self

  # Toggles whether special events/days are displayed
  toggleSpecialDates = ->
    $('.special_date').each ->
      $specialEvent = $(this)
      $elementToHide = $specialEvent

      # If all of the events on this day are special/overridden, hide the entire day
      if !$specialEvent.siblings().not('.special_date').length
        $elementToHide = $specialEvent.closest('tr.date')

      $elementToHide.toggle(specialDatesAreHidden)

    $toggle_special_dates = $('#toggle_special_dates_in_syllabus')
    $toggle_special_dates.removeClass('hidden').removeClass('shown')
    $toggle_special_dates.addClass(if specialDatesAreHidden then 'shown' else 'hidden')
    specialDatesAreHidden = !specialDatesAreHidden

    highlightDaysWithEvents()

  # Binds to #syllabus dom events
  #    Called to bind behaviors to #syllabus after it's rendered.
  bindToSyllabus = ->
    $syllabus = $('#syllabus')
    $syllabus.on 'mouseenter mouseleave', 'tr.date', (ev) ->
      date = $(this).find('.day_date').attr('data-date') if ev.type == 'mouseenter'
      highlightDate date

    $syllabus.on 'mouseenter mouseleave', 'tr.date .detail_list tr', (ev) ->
      related_id = null
      if ev.type == 'mouseenter'
        for c in $(this).attr('class')?.split(/\s+/)
          if c.substr(0, 8) == 'related-'
            related_id = c.substr(8)
            break

      highlightRelated related_id, this

    $toggleSpecialDatesInSyllabus = $('#toggle_special_dates_in_syllabus')
    $toggleSpecialDatesInSyllabus.on 'click', (ev) ->
      ev.preventDefault()
      toggleSpecialDates()

    highlightDaysWithEvents()

    todayString = $.datepicker.formatDate 'yy_mm_dd', new Date
    highlightDate todayString

  selectRow = ($row, e) ->
    if $row.length > 0
      $('tr.selected').removeClass('selected')
      $row.addClass('selected')
      $('html, body').scrollTo $row
      $row.find('a').first().focus()

  selectDate = (date) ->
    $('.mini_month .day.selected').removeClass('selected')
    $('.mini_month').find("#mini_day_#{date}").addClass('selected')

  # Binds to mini calendar dom events
  bindToMiniCalendar = ->
    $mini_month = $('.mini_month')

    prev_next_links = $mini_month.find('.next_month_link, .prev_month_link')
    prev_next_links.on 'click', false
    prev_next_links.on 'mousedown', (ev) ->
      ev.preventDefault()
      calendarMonths.changeMonth $mini_month, if $(this).hasClass('next_month_link') then 1 else -1
      highlightDaysWithEvents()

    $mini_month.on 'click', '.mini_calendar_day', (ev) ->
      ev.preventDefault()
      date = this.id.slice(9)
      [year, month, day] = date.split('_')

      calendarMonths.changeMonth $mini_month, "#{month}/#{day}/#{year}"
      highlightDaysWithEvents()
      selectDate(date)

      $(".events_#{date}").ifExists ($events) ->
        selectRow($events, ev)

    $mini_month.on 'mouseover mouseout', '.mini_calendar_day', (ev) ->
      date = this.id.slice(9) unless ev.type == 'mouseout'
      highlightDate date

    $('.jump_to_today_link').on 'click', (ev) ->
      ev.preventDefault()
      todayString = $.datepicker.formatDate 'yy_mm_dd', new Date
      $lastBefore = undefined
      $('tr.date').each ->
        dateString = $(this).find('.day_date').attr('data-date')
        return false if !dateString || dateString > todayString
        $lastBefore = $(this)

      calendarMonths.changeMonth $mini_month, $.datepicker.formatDate 'mm/dd/yy', new Date
      highlightDaysWithEvents()

      $lastBefore ||= $('tr.date:first')
      selectDate(todayString)
      selectRow($lastBefore, ev)

  # Binds to edit syllabus dom events
  bindToEditSyllabus = ->

    $course_syllabus = $('#course_syllabus')
    $course_syllabus.data('syllabus_body', ENV.SYLLABUS_BODY)
    $edit_syllabus_link = $('.edit_syllabus_link')

    # if there's no edit link, don't need to (and shouldn't) do the rest of
    # this. the edit link is included on the page if and only if the user has
    # :manage_content permission on the course (see assignments'
    # syllabus_right_side view)
    return unless $edit_syllabus_link.length > 0

    # Add the backbone view for keyboardshortup help here
    $('.toggle_views_link').first().before((new KeyboardShortcuts()).render().$el)

    $edit_course_syllabus_form = $('#edit_course_syllabus_form')
    $course_syllabus_body = $('#course_syllabus_body')
    $course_syllabus_details = $('#course_syllabus_details')

    RichContentEditor.initSidebar({
      show: -> $('#sidebar_content').hide(),
      hide: -> $('#sidebar_content').show()
    })

    $edit_course_syllabus_form.on 'edit', ->
      $edit_course_syllabus_form.show()
      $edit_syllabus_link.hide()
      $course_syllabus.hide()
      $course_syllabus_details.hide()
      $course_syllabus_body = RichContentEditor.freshNode($course_syllabus_body)
      $course_syllabus_body.val($course_syllabus.data('syllabus_body'))
      RichContentEditor.loadNewEditor($course_syllabus_body, { focus: true, manageParent: true })

      $('.jump_to_today_link').focus() # a11y: Set focus so it doesn't get lost.

    $edit_course_syllabus_form.on 'hide_edit', ->
      $edit_course_syllabus_form.hide()
      $edit_syllabus_link.show()
      $course_syllabus.show()
      text = $.trim $course_syllabus.html()
      $course_syllabus_details.showIf not text
      RichContentEditor.destroyRCE($course_syllabus_body)

    $edit_syllabus_link.on 'click', (ev) ->
      ev.preventDefault()
      $edit_course_syllabus_form.triggerHandler 'edit'

    $edit_course_syllabus_form.on 'click', '.toggle_views_link', (ev) ->
      ev.preventDefault()
      RichContentEditor.callOnRCE($course_syllabus_body, 'toggle')
      # hide the clicked link, and show the other toggle link.
      # todo: replace .andSelf with .addBack when JQuery is upgraded.
      $(ev.currentTarget).siblings('.toggle_views_link').andSelf().toggle()

    $edit_course_syllabus_form.on 'click', '.cancel_button', (ev) ->
      ev.preventDefault()
      $edit_course_syllabus_form.triggerHandler 'hide_edit'

    $edit_course_syllabus_form.formSubmit
      object_name: 'course'

      processData: (data) ->
        syllabus_body = RichContentEditor.callOnRCE($course_syllabus_body, 'get_code')
        data['course[syllabus_body]'] = syllabus_body
        data

      beforeSubmit: (data) ->
        $edit_course_syllabus_form.triggerHandler 'hide_edit'
        $course_syllabus_details.hide()
        $course_syllabus.loadingImage()

      success: (data) ->
        ###
        xsslint safeString.property syllabus_body
        ###
        $course_syllabus.loadingImage('remove').html data.course.syllabus_body
        $course_syllabus.data('syllabus_body', data.course.syllabus_body)
        $course_syllabus_details.hide()

      error: (data) ->
        $edit_course_syllabus_form.triggerHandler('edit').formErrors data

  return {
    bindToEditSyllabus: bindToEditSyllabus
    bindToMiniCalendar: bindToMiniCalendar
    bindToSyllabus: bindToSyllabus
  }
