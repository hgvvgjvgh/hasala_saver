import 'package:sqflite/sqflite.dart';
import '../model/goal.dart';
import 'app_db.dart';

class GoalRepository {
  Future<int> addGoal(Goal goal) async {
    final db = await AppDb.database;
    return db.insert('goals', goal.toMap());
  }

  Future<List<Goal>> getGoals() async {
    final db = await AppDb.database;
    final rows = await db.query('goals', orderBy: 'created_at DESC');
    return rows.map((e) => Goal.fromMap(e)).toList();
  }

  Future<double> getSavedForGoal(int goalId) async {
    final db = await AppDb.database;
    final res = await db.rawQuery('''
      SELECT COALESCE(SUM(CASE WHEN type='deposit' THEN amount ELSE -amount END), 0) AS saved
      FROM transactions WHERE goal_id=?
    ''', [goalId]);
    return (res.first['saved'] as num).toDouble();
  }

  Future<int> deleteGoal(int id) async {
    final db = await AppDb.database;
    return db.delete('goals', where: 'id=?', whereArgs: [id]);
  }
}