require File.expand_path('../../spec_helper', __FILE__)

describe "Make Exportable" do

  before(:each) do
    clean_database!
  end

  describe NovaFabrica::MakeExportable do

    before(:each) do
      clean_database!
    end

    it "should have constants describing the different that can be exported" do
      NovaFabrica::MakeExportable.exportable_formats.should_not be_nil
      NovaFabrica::MakeExportable.exportable_formats.key?(:csv).should be_true
      NovaFabrica::MakeExportable.exportable_formats.key?(:xls).should be_true
      NovaFabrica::MakeExportable.exportable_formats.key?(:tsv).should be_true
      NovaFabrica::MakeExportable.exportable_formats.key?(:xml).should be_true
      NovaFabrica::MakeExportable.exportable_formats.key?(:html).should be_true
    end

    describe "mattr_accessors" do

      it "should module accessor for exportable tables that starts as an empty hash" do
        #TODO Fails on Rcov because??? Does it load all the before(:all)
        NovaFabrica::MakeExportable.exportable_classes.should == {}
      end

      it "should have a module accessor for supported types" do
        NovaFabrica::MakeExportable.exportable_formats.include?(:csv).should be_true
        NovaFabrica::MakeExportable.exportable_formats.include?(:xls).should be_true
        NovaFabrica::MakeExportable.exportable_formats.include?(:tsv).should be_true
        NovaFabrica::MakeExportable.exportable_formats.include?(:html).should be_true
        NovaFabrica::MakeExportable.exportable_formats.include?(:xml).should be_true
      end

    end

    describe "Module Helper Methods" do

      it "should tell if a format is exportable" do
        NovaFabrica::MakeExportable.exportable_format_supported?(:csv).should be_true
        NovaFabrica::MakeExportable.exportable_format_supported?(:unsupported).should_not be_true
        NovaFabrica::MakeExportable.exportable_formats -= [:csv]
        NovaFabrica::MakeExportable.exportable_format_supported?(:csv).should_not be_true
        #Resetting Exportable Formats to Default
        NovaFabrica::MakeExportable.exportable_formats = [:csv, :xls, :tsv, :html, :xml]
      end

      it "should tell the descriptive name of a format" do
        NovaFabrica::MakeExportable.exportable_formats[:csv].name.should == "Comma-separated (CSV)"
      end

      it "should tell the mime data-type of a format" do
        NovaFabrica::MakeExportable.exportable_formats[:csv].data_type.should == "text/csv; charset=utf-8; header=present"
      end

    end

    describe "making a class exportable" do

      before(:each) do
        class User < ActiveRecord::Base
          make_exportable
        end
      end

      it "should include the class table into the exportable tables attribute" do
        NovaFabrica::MakeExportable.exportable_classes.should == {'User' => User}
      end

      it "should include NovaFabrica's ClassMethods on class" do
        if ActiveRecord::VERSION::MAJOR >= 3
          User.methods.include?(:to_export).should be_true
          User.methods.include?(:get_export_data).should be_true
          User.methods.include?(:create_report).should be_true
        else
          User.methods.include?("to_export").should be_true
          User.methods.include?("get_export_data").should be_true
          User.methods.include?("create_report").should be_true
        end
      end

      it "should include NovaFabrica's InstanceMethods on a class instance" do
        if ActiveRecord::VERSION::MAJOR >= 3
          User.instance_methods.include?(:export_attribute).should be_true
        else
          User.instance_methods.include?("export_attribute").should be_true
        end
      end

      it "should create the class writer exportable_options" do
        if ActiveRecord::VERSION::MAJOR >= 3
          User.instance_methods.include?(:exportable_options).should be_true
        else
          User.instance_methods.include?("exportable_options").should be_true
        end
      end

      describe "inherited singleton methods" do

        before(:each) do
          @user = User.create(:first_name => "Carl", :last_name => "Joans")
        end

        it "should be able to call methods as attributes during exporting" # do
         #          @user.export_attribute('full_name').should == "Carl Joans"
         #        end

        it "should allow custom methods following the #method_export convention" # do
         #          @user.export_attribute('admin').should == "monkey"
         #        end

        #Wouldn't it be better to call an Error?
        it "should not blow up if the attribute doesn't exist" # do
         #          @user.export_attribute('ful_name').should == ""
         #        end
        
      end

      describe "Inherited Class Methods" do

        before(:each) do
          clean_database!

          User.create(:first_name => "user_1", :last_name => "Doe", :created_at => Time.at(0), :updated_at => Time.parse("1/2/3"))
          User.create(:first_name => "user_2", :last_name => "Doe", :created_at => Time.at(0), :updated_at => Time.parse("1/2/3"))
        end

        describe "to_export" do

          context "with explicit columns given" do

            it "should export the columns as csv" do
              User.to_export( "csv", :only => [:first_name, "is_admin"]).should ==  ["First Name,Is Admin\nuser_1,false\nuser_2,false\n", "text/csv; charset=utf-8; header=present"]
            end

            it "should export the columns as xls" do
              User.to_export( "xls", :only =>  [:first_name, "is_admin"]).should == ["<table>\n\t<tr>\n\t\t<th>First Name</th>\n\t\t<th>Is Admin</th>\n\t</tr>\n\t<tr>\n\t\t<td>user_1</td>\n\t\t<td>false</td>\n\t</tr>\n\t<tr>\n\t\t<td>user_2</td>\n\t\t<td>false</td>\n\t</tr>\n</table>\n", "application/vnd.ms-excel; charset=utf-8; header=present"]
            end

            it "should export the columns as tsv" do
              User.to_export( "tsv", :only => [:first_name, "is_admin"]).should == ["First Name\tIs Admin\nuser_1\tfalse\nuser_2\tfalse\n", "text/tab-separated-values; charset=utf-8; header=present"]
            end

            it "should export the columns as html" do
              User.to_export( "html", :only => [:first_name, "is_admin"]).should == ["<table>\n\t<tr>\n\t\t<th>First Name</th>\n\t\t<th>Is Admin</th>\n\t</tr>\n\t<tr>\n\t\t<td>user_1</td>\n\t\t<td>false</td>\n\t</tr>\n\t<tr>\n\t\t<td>user_2</td>\n\t\t<td>false</td>\n\t</tr>\n</table>\n", "text/html; charset=utf-8; header=present"]
            end

            it "should export the columns as xml" do
              User.to_export( "xml", :only => [:first_name, "is_admin"]).should == ["<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<users>\n\t<user>\n\t\t<first-name>user_1</first-name>\n\t\t<is-admin>false</is-admin>\n\t</user>\n\t<user>\n\t\t<first-name>user_2</first-name>\n\t\t<is-admin>false</is-admin>\n\t</user>\n</users>\n", "application/xml; header=present"]
            end

            #We really could test this one forever.
            it "should export the columns designated by the options given" do
              User.to_export( "csv", :columns => [:first_name, "is_admin"], :finder_options => { :conditions => {:first_name => "user_1"}}).should == ["First Name,Is Admin\nuser_1,false\n", "text/csv; charset=utf-8; header=present"]
            end

          end

          context "default columns" do

            it "should export the columns as csv" do
              User.to_export( "csv").should ==  ["Id,First Name,Last Name,Email,Is Admin,Created At,Updated At\n17,user_1,Doe,\"\",false,Wednesday December 31 1969 at 07:00PM,Saturday February 03 2001 at 12:00AM\n18,user_2,Doe,\"\",false,Wednesday December 31 1969 at 07:00PM,Saturday February 03 2001 at 12:00AM\n", "text/csv; charset=utf-8; header=present"]
            end

            it "should export the columns as xls" do
              User.to_export( "xls").should == ["<table>\n\t<tr>\n\t\t<th>Id</th>\n\t\t<th>First Name</th>\n\t\t<th>Last Name</th>\n\t\t<th>Email</th>\n\t\t<th>Is Admin</th>\n\t\t<th>Created At</th>\n\t\t<th>Updated At</th>\n\t</tr>\n\t<tr>\n\t\t<td>19</td>\n\t\t<td>user_1</td>\n\t\t<td>Doe</td>\n\t\t<td></td>\n\t\t<td>false</td>\n\t\t<td>Wednesday December 31 1969 at 07:00PM</td>\n\t\t<td>Saturday February 03 2001 at 12:00AM</td>\n\t</tr>\n\t<tr>\n\t\t<td>20</td>\n\t\t<td>user_2</td>\n\t\t<td>Doe</td>\n\t\t<td></td>\n\t\t<td>false</td>\n\t\t<td>Wednesday December 31 1969 at 07:00PM</td>\n\t\t<td>Saturday February 03 2001 at 12:00AM</td>\n\t</tr>\n</table>\n", "application/vnd.ms-excel; charset=utf-8; header=present"]
            end

            it "should export the columns as tsv" do
              User.to_export( "tsv").should == ["Id\tFirst Name\tLast Name\tEmail\tIs Admin\tCreated At\tUpdated At\n21\tuser_1\tDoe\t\tfalse\tWednesday December 31 1969 at 07:00PM\tSaturday February 03 2001 at 12:00AM\n22\tuser_2\tDoe\t\tfalse\tWednesday December 31 1969 at 07:00PM\tSaturday February 03 2001 at 12:00AM\n", "text/tab-separated-values; charset=utf-8; header=present"]
            end

            it "should export the columns as html" do
              User.to_export( "html").should == ["<table>\n\t<tr>\n\t\t<th>Id</th>\n\t\t<th>First Name</th>\n\t\t<th>Last Name</th>\n\t\t<th>Email</th>\n\t\t<th>Is Admin</th>\n\t\t<th>Created At</th>\n\t\t<th>Updated At</th>\n\t</tr>\n\t<tr>\n\t\t<td>23</td>\n\t\t<td>user_1</td>\n\t\t<td>Doe</td>\n\t\t<td></td>\n\t\t<td>false</td>\n\t\t<td>Wednesday December 31 1969 at 07:00PM</td>\n\t\t<td>Saturday February 03 2001 at 12:00AM</td>\n\t</tr>\n\t<tr>\n\t\t<td>24</td>\n\t\t<td>user_2</td>\n\t\t<td>Doe</td>\n\t\t<td></td>\n\t\t<td>false</td>\n\t\t<td>Wednesday December 31 1969 at 07:00PM</td>\n\t\t<td>Saturday February 03 2001 at 12:00AM</td>\n\t</tr>\n</table>\n", "text/html; charset=utf-8; header=present"]
            end

            it "should export the columns as xml" do
              User.to_export( "xml").should ==["<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<users>\n\t<user>\n\t\t<id>25</id>\n\t\t<first-name>user_1</first-name>\n\t\t<last-name>Doe</last-name>\n\t\t<email></email>\n\t\t<is-admin>false</is-admin>\n\t\t<created-at>Wednesday December 31 1969 at 07:00PM</created-at>\n\t\t<updated-at>Saturday February 03 2001 at 12:00AM</updated-at>\n\t</user>\n\t<user>\n\t\t<id>26</id>\n\t\t<first-name>user_2</first-name>\n\t\t<last-name>Doe</last-name>\n\t\t<email></email>\n\t\t<is-admin>false</is-admin>\n\t\t<created-at>Wednesday December 31 1969 at 07:00PM</created-at>\n\t\t<updated-at>Saturday February 03 2001 at 12:00AM</updated-at>\n\t</user>\n</users>\n", "application/xml; header=present"]
            end

            #We really could test this one forever.
            it "should export the columns designated by the options given" do
              User.to_export( "csv", :finder_options => {:conditions => {:first_name => "user_1"}}).should ==["Id,First Name,Last Name,Email,Is Admin,Created At,Updated At\n27,user_1,Doe,\"\",false,Wednesday December 31 1969 at 07:00PM,Saturday February 03 2001 at 12:00AM\n", "text/csv; charset=utf-8; header=present"]
            end
          end

        end

        describe "get_export_data" do

          it "should create order array of arrays of ordered column data" do
            User.get_export_data([:first_name, :last_name]).should == [["user_1", "Doe"], ["user_2", "Doe"]]
          end

          it "should chainable on named_scopes" do
            User.a_limiter.get_export_data([:first_name, :last_name]).should == [["user_1", "Doe"]]
          end

          it "should allow a scope to be sent" do
            User.get_export_data([:first_name, :last_name], :scopes => ['a_limiter']).should == [["user_1", "Doe"]]
          end

          it "should allow multiple scopes to be sent" do
            User.get_export_data([:first_name, :last_name], :scopes => ['a_limiter', "order_by"]).should == [["user_2", "Doe"]]
          end

          it "should create order array of arrays of ordered column data by the options given" do
            User.get_export_data([:first_name, :last_name], :finder_options => {:order => " ID DESC"}).should == [["user_2", "Doe"], ["user_1", "Doe"]]

            User.get_export_data([:first_name, :last_name],  :finder_options => {:conditions => {:first_name => "user_1"}}).should == [["user_1", "Doe"]]
          end

        end

        describe "create_report" do

          it "should raise an FormatNotFound if the format is not supported" do
            lambda do
              User.create_report("NONSUPPORTED")
            end.should raise_error(NovaFabrica::MakeExportable::FormatNotFound)
          end

          it 'should export an array of header and array of arrays of rows in the specified format' do
            User.create_report("csv", ["Title", "Another Title"], [[ "data", 'lovely data'],["", "more lovely data"]]).should == ["Title,Another Title\ndata,lovely data\n\"\",more lovely data\n", "text/csv; charset=utf-8; header=present"]
          end

          it "should raise an ExportFault if the datasets are not all the same size" do
            lambda do
              User.create_report("csv", ["Title", "Another Title"], [[ "data", 'lovely data'],["more lovely data"]])
            end.should raise_error(NovaFabrica::MakeExportable::ExportFault)
          end

        end

      end

      before(:each) do
        NovaFabrica::MakeExportable.exportable_formats = [:csv, :xls, :tsv, :html, :xml]
      end

      describe " dynamically named classes" do

        describe "create_format_for" do

          NovaFabrica::MakeExportable.exportable_formats.map do |format|
            it "should create the method create_#{format}_for" do
              User.should_receive(:create_report).with("#{format}")
              User.send("create_#{format}_for")
            end
          end

          it "should not create a method if the format is not supported" do
            NovaFabrica::MakeExportable.exportable_formats -= [:csv]
            lambda do
              User.create_csv_for
            end.should raise_error(NoMethodError)
          end

        end

        describe "create_format_report_for" do

          NovaFabrica::MakeExportable.exportable_formats.map do |format|
            it "should create the method create_#{format}_report_for" do
              User.should_receive(:create_report).with("#{format}")
              User.class_eval("create_#{format}_report_for")
            end
          end

          it "should not create a method if the format is not supported" do
            NovaFabrica::MakeExportable.exportable_formats -= [:csv]
            lambda do
              User.create_csv_for
            end.should raise_error(NoMethodError)
          end

        end

        describe "to_format_report" do

          NovaFabrica::MakeExportable.exportable_formats.map do |format|
            it "should create the method to_#{format}_report" do
              User.should_receive(:to_export).with("#{format}")
              User.class_eval("to_#{format}_report")
            end
          end

          it "should not create a method if the format is not supported" do
            NovaFabrica::MakeExportable.exportable_formats -= [:csv]
            lambda do
              User.create_csv_for
            end.should raise_error(NoMethodError)
          end

        end


      end

    end

  end

end
