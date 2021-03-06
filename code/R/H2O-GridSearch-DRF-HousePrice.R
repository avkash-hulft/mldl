###: Loading H2O Library
library(h2o)

###: Initalizing H2O cluster
h2o.init()

###: Get H2O Version
h2o.getVersion()

###: Importing both training and test dataset into H2O cluster memory
train_df = h2o.importFile("https://raw.githubusercontent.com/Avkash/mldl/master/data/house_price_train.csv")
test_df = h2o.importFile("https://raw.githubusercontent.com/Avkash/mldl/master/data/house_price_test.csv")

###: Listing all columns
h2o.colnames(train_df)

###: Setting response variable
response = "medv"

###: Settings all features for supervised machine learning
features =  h2o.colnames(train_df)
print(features)

###: Creating a list of all features we will use for machine learning
features = setdiff(features, response)
print(features)

###: Ignoring other features which are not needed for training
###: features = setdiff(features, c('list_of_columns_you_want_to_ignore'))
###: print(features)    

###: Understanding response variable values as historgram in Training data
h2o.hist(h2o.asnumeric(train_df[response]))

###:Training classification model with cross validation
drf_model_with_cv = h2o.randomForest(nfolds=5, 
                            x = features, y = response, training_frame=train_df)

###: Getting model performance
h2o.performance(drf_model_with_cv, xval = TRUE)
h2o.r2(drf_model_with_cv, xval = TRUE)

###:Training classification model with cross validation and key parameters configuration
drf_model_cv_config = h2o.randomForest(nfolds=5,
                              keep_cross_validation_predictions=TRUE,
                              fold_assignment="Modulo",
                              seed=12345,
                              ntrees=10,
                              max_depth=3,
                              min_rows=2,
                              learn_rate=0.2,
                              x = features, 
                              y = response, 
                              training_frame=train_df, 
                              model_id = "drf_model_with_training_and_validtion_R")

###: Getting DRF model performance on test data
h2o.performance(drf_model_cv_config, xval = TRUE)
h2o.r2(drf_model_cv_config, xval = TRUE)

###: Settings GBM grid parameters
drf_hyper_params = list(max_depth =  c(5, 7, 10),
                        sample_rate = c(0.5, 0.75, 1.0),
                        ntrees = c(5,25,50))

###: Setting H2O Grid Search Criteria
grid_search_criteria = list( 'strategy'= "RandomDiscrete", 
                    'seed'= 123,
                    'stopping_metric'= "AUTO", 
                    'stopping_tolerance'= 0.01,
                    'stopping_rounds' = 5 )

###: Training H2O Grid with data and H2O Grid searching settings
drf_grid = h2o.grid(
                     hyper_params=drf_hyper_params,
                     search_criteria=grid_search_criteria,
                     grid_id="houseprice_drf_grid_R",
                     algorithm = "drf"  ,
                     nfolds=5,
                     keep_cross_validation_predictions=TRUE,
                     fold_assignment="Modulo",
                     seed=12345,
                     x=features, y=response, training_frame=train_df
                    )

###: Finally getting the grid details based on AUC metric,  from ascending to descending sorted order
result_grid = h2o.getGrid("houseprice_drf_grid_R", sort_by = "r2", decreasing = TRUE)

###: understanding grid
result_grid

###: Getting Grid Rows and Columns
print(nrow(result_grid@summary_table))
print(ncol(result_grid@summary_table))

###: Getting grid table header from the grid 
names(result_grid@summary_table)

###: Getting specific column details  from the grid
result_grid@summary_table['sample_rate']
result_grid@summary_table['max_depth']
result_grid@summary_table['r2']

###: Getting max metric (auc) from the grid
r2_list = result_grid@summary_table['r2'][[1]]
max(r2_list)

###: Getting Top 5 sample_rate values based on r2 sorted list, and then findings min and max of sample_rate from the top 5 r2 results
sample_rate_values = result_grid@summary_table$sample_rate[1:5]
sample_rate_values
min_sample_rate = as.numeric(min(sample_rate_values))
max_sample_rate = as.numeric(max(sample_rate_values))

###: Getting Top 5 max_depth values based on r2 sorted list, and then findings min and max of max_depth from the top 5 r2 results
max_depth_values = result_grid@summary_table$max_depth[1:5]
max_depth_values

min_max_depth = as.numeric(min(max_depth_values))
max_max_depth = as.numeric(max(max_depth_values))

###: Now we can retrain the model based on selected learn_rate and max_depth values above
###: This is how you will set the updated DRF grid parameters based on grid search hyperparameter and retrain the grid
drf_hyper_params = list(learn_rate = seq(min_sample_rate,max_sample_rate,1), 
                        max_depth =  seq(min_max_depth, max_max_depth, 1))

###: Getting the 5 best model from the grid
for (i in 1:5) {
  drf_model = h2o.getModel(result_grid@model_ids[[i]])
  print(h2o.r2(h2o.performance(drf_model, xval = TRUE)))
}

###: Getting the best model from the grid which is the first/top model from the R2 based sorted list 
best_model = h2o.getModel(result_grid@model_ids[[1]])

###: Getting the best model performance on test data
h2o.r2(best_model, xval = TRUE)

###: Performing predictions with one of the above model
model_predictions = h2o.predict(best_model, newdata = test_df)
model_predictions

###: Understanding/Validating predictions based on prediction results historgram
h2o.hist(model_predictions)

###: Getting Scorring History
h2o.scoreHistory(best_model)

###: Getting model variable importance 
h2o.varimp(best_model)

###: Getting model variable importance PLOT
h2o.varimp_plot(best_model)
