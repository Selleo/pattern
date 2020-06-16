class Rule
  def initialize(subject)
    @subject = subject
  end

  def satisfied?
    raise NotImplementedError
  end

  def not_applicable?
    false
  end

  def applicable?
    !not_applicable?
  end

  def forceable?
    true
  end

  private

  attr_reader :subject
end
