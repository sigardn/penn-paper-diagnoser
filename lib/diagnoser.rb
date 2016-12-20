require 'lib/paper_size'

class Diagnoser
  attr_reader :sorted_matches

  def initialize
    @formats = %i(folio agenda_quarto quarto octavo sixteen_mo)
    @names   = %i(imperial super_royal royal super_median median super_chancery chancery mezzo_median)
    @formats << :full_sheet if $single

    @papersizes = []
    @names.each do |n|; @formats.each do |f|
      @papersizes << PaperSize.new(n,f)
    end; end
    # ---------------------------------------
    # @formats.each do |f|
    #   @names.each do |n|
    #     @papersizes << PaperSize.new(n,f)
    #   end
    # end
    # ---------------------------------------
    # @papersizes = @names.flat_map do |n|
    #   @formats.map{ |f| PaperSize.new(n,f)}
    # end
    # ---------------------------------------

    @exclusion = Hash.new([])
    @exclusion['vertical']   = %i(quarto sixteen_mo full_sheet)
    @exclusion['horizontal'] = %i(folio agenda_quarto octavo)
  end

  def lock_format(f)
    @exclusion = Hash.new(%i[folio agenda_quarto quarto octavo sixteen_mo])
  end

  def find_matches(height, width, chain)
    possible_formats = @formats - @exclusion[chain]
    @matches = @papersizes.select do |ps|
      possible_formats.include?(ps.format) && height <= ps.height && width <= ps.width
    end
  end

  def sort_by_dim(dim)
    @sorted_matches = @matches.sort_by{ |m| m.measure(dim) }
  end

  def get_results(deckle_tobo, deckle_side)
    sm0 = @sorted_matches[0]
    sm1 = @sorted_matches[1]
    return []    if sm0.nil?
    return [sm0] if sm1.nil?
    if deckle_tobo && deckle_side
      equal_area = sm1.area == sm0.area
      equal_area ? ["#{sm0} or #{sm1}"] : [sm0]
    elsif deckle_tobo || deckle_side
      dim = deckle_tobo ? :h : :w
      sd  = sort_by_dim(dim)
      return [sd[0]] if sd[0].measure(dim) < sm0.measure(dim)
      second_place = sd.find{ |p| p != sm0 && p.measure(dim) == sm0.measure(dim) }
      second_place ? [sm0, second_place] : [sm0]
    else
      sm2 = @sorted_matches[2]
      median_exception = [sm0, sm1, sm2].map(&:name) == %i(chancery super_chancery median)
      median_exception ? [sm0, sm1, sm2] : [sm0, sm1]
    end
  end

  def sheet_note(format, deckle_t, deckle_b)
    if format == :quarto
      deck      = 'top'
      condition = deckle_t
    else
      deck      = 'top and bottom'
      condition = deckle_t && deckle_b
    end
    sheet_size = {quarto: 'half-sheets', octavo: 'quarter-sheets', sixteen_mo: 'eighth-sheets'}[format]
    condition ? {fmt: format.to_s.upcase.sub('SIXTEEN_MO', '16mo'), deck: deck, sh: sheet_size} : nil
  end

# def super_check(ps1, ps2, dim = nil)
#   return [ps1, ps2] unless ps1.name == :chancery && ps2.name == :super_chancery
#   med = PaperSize.new(ps1.format, :median)
#   return [ps1, ps2] if dim && med.measure(dim) > ps1.measure(dim)
#   [ps1, ps2, med]
# end
end

