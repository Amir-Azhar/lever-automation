# frozen_string_literal: true

#
# Logic for rules we wish to apply
#

class Rules

  # list of tags for each category, so we can remove when updating with new values
  def all_tags
    {
      source: {
        sourced: 'Sourced',
        referral: 'Referral',
        organic: 'Organic',
        offline: 'Offline',
        offline_organic: 'Offline-or-Organic',
        error: '<error:unknown>'
      }
    }  
  end
  
  def self.source_from_application(opp, responses)
    return {msg: 'No application'} if !Util.has_application(opp)
    return {msg: "Couldn't find custom question responses."} if responses.nil?

    # 1: "who referred you"
    responses.each {|qu|
      tags = tags(:source)
      if qu[:_text].include?('who referred you')
        return {tag: tags[:referral], field: qu['text'], value: "<not empty>"} if qu['value'] > ''
        break
      end
    }

    responses.each {|qu|
      if qu[:_text].include?('who told you about ef')
        map = [
          ['been on the ef programme', tag: tags[:referral]],
          ['worked at ef', tag: tags[:referral]],
          ['professional network', tag: tags[:organicl]],
          ['friends or family', tag: tags[:organic]]
        ]
        source = nil
        map.each { |m|
          source = m[1] if qu[:_value].include? m[0]
        }
        return {tag: source, field: qu['text'], value: qu['value']} unless source.nil?
        break
      end
    }

    responses.each {|qu|
      if qu[:_text].include?('how did you hear about ef')
        map = [
          ['directly contacted by ef', tags[:sourced]],
          ['cohort member', tags[:referral]],
          ['someone else', tags[:organic]], # if not already covered above by latter questions
          ['came across ef', tags[:offline_organic]],
          ['event', tags[:offline]]
        ]
        source = nil
        map.each { |m|
          source = m[1] if qu[:_value].include? m[0]
        }
        return {source: source, field: qu['text'], value: qu['value']} unless source.nil?
        break
      end
    }
    
    # otherwise, unable to determine source from application
    nil
  end

  def self.summarise_one_feedback(f)
    result = {}
    
    result
  end

  def self.summarise_all_feedback(summaries)
    result = {}
    
    result
  end

  def self.update_tags(opp, add, remove, add_note)
    self.tag_source_from_application(opp, add, remove, add_note)
  end
  
  # automatically add tag for the opportunity source based on self-reported data in the application
  def self.tag_source_from_application(opp, add, remove, add_note)
    return if !Util.has_application(opp) || !Util.is_cohort_app(opp)

    tag = tags(:source, :error) # default
    source = Rules.source_from_application(opp, opp['_app_responses'])
    tag = source[:source] unless source.nil? || source[:source].nil?
    
    add(TAG_SOURCE_FROM_APPLICATION + tag)
    remove(tags(:source).reject {|k,v| k == tag}.values.map{|t| TAG_SOURCE_FROM_APPLICATION + t})
    
    log.log("Added tag #{TAG_SOURCE_FROM_APPLICATION}#{tag} because field \"#{source[:field]}\" is \"#{ (source[:value].class == Array ?
      source[:value].join('; ') : source[:value]) }\"")
  end

  # helpers

  def tags(category=nil, name=nil)
    if category.nil?
      all_tags
    elsif name.nil?
      all_tags[category]
    else
      all_tags[category][name]
    end
  end
  
end
