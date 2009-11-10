class Webcat::Session
  attr_reader :mode, :app

  def initialize(mode, app)
    @mode = mode
    @app = app
  end

  def driver
    @driver ||= case mode
    when :rack_test
      Webcat::Driver::RackTest.new(app)
    when :culerity
      Webcat::Driver::Culerity.new(app)
    else
      raise Webcat::DriverNotFoundError, "no driver called #{mode} was found"
    end
  end

  def visit(path)
    driver.visit(path)
  end
  
  def click_link(locator)
    find_element("//a[@id='#{locator}']", %{//a[text()="#{locator}"]}, %{//a[@title="#{locator}"]}).click
  end

  def click_button(locator)
    find_element("//input[@type='submit'][@id='#{locator}']", "//input[@type='submit'][@value='#{locator}']").click
  end

  def fill_in(locator, options={})
    find_field(locator, :text_field, :text_area).set(options[:with])
  end

  def body
    driver.body
  end

private

  def find_field(locator, *kinds)
    find_field_by_id(locator, *kinds) or find_field_by_label(locator, *kinds)
  end

  FIELDS_PATHS = {
    :text_field => proc { |id| "//input[@type='text'][@id='#{id}']" },
    :text_area => proc { |id| "//textarea[@id='#{id}']" } 
  }

  def find_field_by_id(locator, *kinds)
    kinds.each do |kind|
      path = FIELDS_PATHS[kind]
      element = driver.find(path.call(locator)).first
      return element if element
    end
    return nil
  end

  def find_field_by_label(locator, *kinds)
    kinds.each do |kind|
      label = driver.find("//label[text()='#{locator}']").first
      if label
        element = find_field_by_id(label[:for], kind)
        return element if element
      end
    end
    return nil
  end

  def find_element(*locators)
    locators.each do |locator|
      element = driver.find(locator).first
      return element if element
    end
    raise Webcat::ElementNotFound, "element not found"
  end
  
end
