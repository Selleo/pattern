class Rails
  def self.cache
    @cache ||= ActiveSupport::Cache::RedisCacheStore.new
  end
end
