module Arel
  module Visitors
    class Jet < Arel::Visitors::ToSql
      def visit_Arel_Nodes_SelectStatement o
        [
          (visit(o.with) if o.with),
          o.cores.map { |x| visit_Arel_Nodes_SelectCore x }.join,
          ("ORDER BY #{o.orders.map { |x| visit x }.join(', ')}" unless o.orders.empty?),
          (visit(o.offset) if o.offset),
          (visit(o.lock) if o.lock),
        ].compact.join ' '
      end

      def visit_Arel_Nodes_SelectCore o
        [
          "SELECT",
          (visit(o.top) if o.top),
          (visit(o.set_quantifier) if o.set_quantifier),
          ("#{o.projections.map { |x| visit x }.join ', '}" unless o.projections.empty?),
          ("FROM #{visit(o.source)}" if o.source && !o.source.empty?),
          ("WHERE #{o.wheres.map { |x| visit x }.join ' AND ' }" unless o.wheres.empty?),
          ("GROUP BY #{o.groups.map { |x| visit x }.join ', ' }" unless o.groups.empty?),
          (visit(o.having) if o.having),
        ].compact.join ' '
      end

      # FIXME: this does nothing on most databases, but does on MSSQL
      def visit_Arel_Nodes_Top o
        "TOP #{visit o.expr}"
      end
    end
  end
end
