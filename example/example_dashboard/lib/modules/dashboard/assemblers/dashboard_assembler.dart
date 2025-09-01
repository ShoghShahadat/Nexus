import 'package:nexus/nexus.dart';
import 'package:example_dashboard/modules/dashboard/assemblers/header_assembler.dart';
import 'package:example_dashboard/modules/dashboard/assemblers/stats_card_assembler.dart';

/// این Assembler اصلی، مسئولیت هماهنگی و ساخت تمام موجودیت‌های ماژول داشبورد را بر عهده دارد.
/// این کلاس جایگزین EntityProvider قبلی شده است.
class DashboardAssembler extends EntityAssembler<void> {
  DashboardAssembler(super.world, super.context);

  @override
  List<Entity> assemble() {
    // FIX: Correctly pass `null` as the second argument to the assemblers.
    // This resolves the 'not_enough_positional_arguments' error.
    // اصلاح: مقدار `null` به عنوان آرگومان دوم به assemblerها به درستی پاس داده شد.
    // این کار خطای 'not_enough_positional_arguments' را برطرف می‌کند.
    final headerAssembler = HeaderAssembler(world, null);
    final statsCardAssembler = StatsCardAssembler(world, null);

    final header = headerAssembler.assemble().first;
    final statsCards = statsCardAssembler.assemble();

    // ساختار سلسله‌مراتبی UI را با استفاده از ChildrenComponent تعریف می‌کنیم.
    final root = world.rootEntity;
    root.add(ChildrenComponent([
      header.id,
      ...statsCards.map((e) => e.id),
    ]));

    // تمام موجودیت‌های ساخته‌شده را به دنیا اضافه می‌کنیم.
    world.addEntity(header);
    for (var card in statsCards) {
      world.addEntity(card);
    }

    // این Assembler اصلی موجودیت جدیدی ایجاد نمی‌کند، بلکه فرآیند را مدیریت می‌کند.
    return [header, ...statsCards];
  }
}
