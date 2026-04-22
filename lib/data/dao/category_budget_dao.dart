import 'package:cashly/data/models/category_budget.dart';
import 'package:floor/floor.dart';

@dao
abstract class CategoryBudgetDao {
  @Query('SELECT * FROM CategoryBudget')
  Future<List<CategoryBudget>> findAll();

  @Query('SELECT * FROM CategoryBudget WHERE category = :category LIMIT 1')
  Future<CategoryBudget?> findByCategory(String category);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertBudget(CategoryBudget budget);

  @update
  Future<void> updateBudget(CategoryBudget budget);

  @delete
  Future<void> deleteBudget(CategoryBudget budget);

  @Query('DELETE FROM CategoryBudget WHERE category = :category')
  Future<void> deleteByCategory(String category);

  @Query('DELETE FROM CategoryBudget')
  Future<void> deleteAll();
}
