class Riemann::Tools::UptimeParser
token AM PM UP DAYS HRS MINS SECS USERS LOAD_AVERAGES
  INTEGER FLOAT
rule
  target: time uptime ',' users ',' load_averages { result = { uptime: val[1], users: val[3], load_averages: val[5] } }

  time: INTEGER ':' INTEGER
      | INTEGER ':' INTEGER AM
      | INTEGER ':' INTEGER PM
      | INTEGER ':' INTEGER ':' INTEGER

  uptime: UP uptime_days uptime_hr_min { result = val[1] + val[2] }
        | UP uptime_days uptime_hr     { result = val[1] + val[2] }
        | UP uptime_days uptime_min    { result = val[1] + val[2] }
        | UP uptime_days uptime_sec    { result = val[1] + val[2] }
        | UP uptime_hr_min             { result = val[1] }
        | UP uptime_hr                 { result = val[1] }
        | UP uptime_min                { result = val[1] }
        | UP uptime_sec                { result = val[1] }

  uptime_days: INTEGER DAYS ',' { result = val[0][:value] * 86400 }

  uptime_hr_min: INTEGER ':' INTEGER { result = val[0][:value] * 3600 + val[2][:value] * 60 }

  uptime_hr: INTEGER HRS { result = val[0][:value] * 3600 }

  uptime_min: INTEGER MINS { result = val[0][:value] * 60 }

  uptime_sec: INTEGER SECS { result = val[0][:value] }

  users: INTEGER USERS { result = val[0][:value] }

  load_averages: LOAD_AVERAGES FLOAT FLOAT FLOAT         { result = { 1 => val[1][:value], 5 => val[2][:value], 15 => val[3][:value] } }
               | LOAD_AVERAGES FLOAT ',' FLOAT ',' FLOAT { result = { 1 => val[1][:value], 5 => val[3][:value], 15 => val[5][:value] } }
end


---- header

require 'strscan'

require 'riemann/tools/utils'

---- inner

  def parse(text)
    s = Utils::StringTokenizer.new(text)

    until s.eos? do
      case
      when s.scan(/\n/)              then s.push_token(nil)
      when s.scan(/\s+/)             then s.push_token(nil)

      when s.scan(/:/)               then s.push_token(':')
      when s.scan(/,/)               then s.push_token(',')
      when s.scan(/\d+[,.]\d+/)      then s.push_token(:FLOAT, s.matched.sub(',', '.').to_f)
      when s.scan(/\d+/)             then s.push_token(:INTEGER, s.matched.to_i)
      when s.scan(/AM/)              then s.push_token(:AM)
      when s.scan(/PM/)              then s.push_token(:PM)
      when s.scan(/up/)              then s.push_token(:UP)
      when s.scan(/days?/)           then s.push_token(:DAYS)
      when s.scan(/hrs?/)            then s.push_token(:HRS)
      when s.scan(/mins?/)           then s.push_token(:MINS)
      when s.scan(/secs?/)           then s.push_token(:SECS)
      when s.scan(/users?/)          then s.push_token(:USERS)
      when s.scan(/load averages?:/) then s.push_token(:LOAD_AVERAGES)
      else
        raise s.unexpected_token
      end
    end

    @tokens = s.tokens

    do_parse
  end

  def next_token
    @tokens.shift
  end

  def on_error(error_token_id, error_value, value_stack)
    raise(Racc::ParseError, "parse error on value \"#{error_value[:value]}\" (#{token_to_str(error_token_id)}) on line #{error_value[:lineno]}:\n#{error_value[:line]}\n#{' ' * error_value[:pos]}^#{'~' * (error_value[:value].to_s.length - 1)}")
  end
