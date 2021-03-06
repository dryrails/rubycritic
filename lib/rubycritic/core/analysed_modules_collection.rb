# frozen_string_literal: true

require 'rubycritic/source_locator'
require 'rubycritic/core/analysed_module'

module RubyCritic
  class AnalysedModulesCollection
    include Enumerable

    # Limit used to prevent very bad modules to have excessive impact in the
    # overall result. See #limited_cost_for
    COST_LIMIT = 32
    # Score goes from 0 (worst) to 100 (perfect)
    MAX_SCORE = 100
    # Projects with an average cost of 16 (or above) will score 0, since 16
    # is where the worst possible rating (F) starts
    ZERO_SCORE_COST = 16
    COST_MULTIPLIER = MAX_SCORE.to_f / ZERO_SCORE_COST

    def initialize(paths)
      @modules = SourceLocator.new(paths).pathnames.map do |pathname|
        AnalysedModule.new(pathname: pathname)
      end
    end

    def each(&block)
      @modules.each(&block)
    end

    def to_json(*options)
      @modules.to_json(*options)
    end

    def score
      if @modules.any?
        MAX_SCORE - average_limited_cost * COST_MULTIPLIER
      else
        0.0
      end
    end

    def summary
      AnalysisSummary.generate(self)
    end

    def for_rating(rating)
      find_all { |mod| mod.rating.to_s == rating }
    end

    private

    def average_limited_cost
      [average_cost, ZERO_SCORE_COST].min
    end

    def average_cost
      num_modules = @modules.size
      if num_modules > 0
        map { |mod| limited_cost_for(mod) }.reduce(:+) / num_modules.to_f
      else
        0.0
      end
    end

    def limited_cost_for(mod)
      [mod.cost, COST_LIMIT].min
    end
  end
end
